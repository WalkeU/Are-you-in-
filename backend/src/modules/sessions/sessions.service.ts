import { prisma } from "../../lib/prisma";
import { AppError } from "../../utils/errors";
import { shuffle } from "../../utils/shuffle";
import type { ResponseRole } from "@prisma/client";

const kinkSelect = { id: true, name: true, description: true, hasRoleVariant: true, roleA: true, roleB: true } as const;

async function getSessionOrThrow(sessionId: string) {
  const session = await prisma.gameSession.findUnique({
    where: { id: sessionId },
    include: { items: { include: { kink: { select: kinkSelect } } } },
  });
  if (!session) throw AppError.notFound("Game session not found");
  return session;
}

function assertParticipant(session: { initiatorId: string; partnerId: string }, userId: string) {
  if (session.initiatorId !== userId && session.partnerId !== userId) {
    throw AppError.forbidden("You are not a participant in this session");
  }
}

/**
 * Both wanting "yes" isn't enough for a role-variant kink - two people both wanting to
 * take the same role can't actually happen together. A missing role
 * (no role variant, or the picker was skipped) is treated as flexible/compatible with
 * anything; only ROLE_A+ROLE_A and ROLE_B+ROLE_B are excluded.
 */
function rolesAreCompatible(roleA: ResponseRole | null, roleB: ResponseRole | null): boolean {
  if (!roleA || !roleB || roleA === "BOTH" || roleB === "BOTH") return true;
  return roleA !== roleB;
}

export async function createSession(
  initiatorId: string,
  itemCount: number,
  maxIntensity: number = 1,
  exactIntensity: boolean = false,
) {
  const initiator = await prisma.user.findUniqueOrThrow({ where: { id: initiatorId } });
  if (!initiator.partnerId) {
    throw AppError.badRequest("You need a paired partner before starting a session");
  }

  const existing = await prisma.gameSession.findFirst({
    where: {
      status: { in: ["PENDING", "ACTIVE"] },
      OR: [
        { initiatorId, partnerId: initiator.partnerId },
        { initiatorId: initiator.partnerId, partnerId: initiatorId },
      ],
    },
  });
  if (existing) {
    throw AppError.conflict("There is already an in-progress session with your partner", { sessionId: existing.id });
  }

  // "Exact" draws only from that one tier; otherwise anything at or below the chosen
  // hardness is fair game, like a spice-level cap rather than a single fixed shelf.
  const intensityFilter = exactIntensity ? { equals: maxIntensity } : { lte: maxIntensity };

  const totalKinks = await prisma.kink.count({ where: { intensity: intensityFilter } });
  if (totalKinks === 0) {
    throw AppError.badRequest("No items match the selected intensity; try a different setting");
  }
  const clampedCount = Math.min(itemCount, totalKinks);

  const allKinkIds = await prisma.kink.findMany({ where: { intensity: intensityFilter }, select: { id: true } });
  const chosenIds = shuffle(allKinkIds).slice(0, clampedCount);

  // Each participant gets their own independently-shuffled viewing order, generated once
  // here and stored, so resuming after a re-fetch (e.g. leaving and reopening the round)
  // continues in the same order instead of jumbling the deck on every load.
  const positions = chosenIds.map((_, i) => i);
  const initiatorOrders = shuffle(positions);
  const partnerOrders = shuffle(positions);

  const session = await prisma.gameSession.create({
    data: {
      initiatorId,
      partnerId: initiator.partnerId,
      itemCount: clampedCount,
      status: "PENDING",
      items: {
        create: chosenIds.map((k, idx) => ({
          kinkId: k.id,
          initiatorOrder: initiatorOrders[idx],
          partnerOrder: partnerOrders[idx],
        })),
      },
    },
    include: { items: { include: { kink: { select: kinkSelect } } } },
  });

  return session;
}

/** Called on logout so a partner mid-round doesn't keep waiting on someone who's left. */
export async function cancelActiveSessionsForUser(userId: string) {
  await prisma.gameSession.updateMany({
    where: {
      status: { in: ["PENDING", "ACTIVE"] },
      OR: [{ initiatorId: userId }, { partnerId: userId }],
    },
    data: { status: "CANCELLED" },
  });
}

const STALE_SESSION_THRESHOLD_MS = 12 * 60 * 60 * 1000;

/**
 * A round nobody accepted or finished in 12h is almost certainly abandoned - clearing
 * it out stops it cluttering "in progress" lists and blocking the pair from starting a
 * fresh one (createSession rejects a new round while an old PENDING/ACTIVE one exists).
 */
export async function expireStaleSessions(): Promise<number> {
  const cutoff = new Date(Date.now() - STALE_SESSION_THRESHOLD_MS);
  const { count } = await prisma.gameSession.updateMany({
    where: { status: { in: ["PENDING", "ACTIVE"] }, createdAt: { lt: cutoff } },
    data: { status: "CANCELLED" },
  });
  return count;
}

export async function listPendingSessions(userId: string) {
  return prisma.gameSession.findMany({
    where: { partnerId: userId, status: "PENDING" },
    orderBy: { createdAt: "desc" },
    include: { initiator: { select: { id: true, name: true } } },
  });
}

export async function listActiveSessions(userId: string) {
  return prisma.gameSession.findMany({
    where: {
      status: { in: ["PENDING", "ACTIVE"] },
      OR: [{ initiatorId: userId }, { partnerId: userId }],
    },
    orderBy: { createdAt: "desc" },
  });
}

export async function acceptSession(sessionId: string, userId: string) {
  const session = await getSessionOrThrow(sessionId);
  if (session.partnerId !== userId) throw AppError.forbidden("Only the invited partner can accept this session");
  if (session.status !== "PENDING") throw AppError.conflict("This session is no longer pending");

  return prisma.gameSession.update({
    where: { id: sessionId },
    data: { status: "ACTIVE", acceptedAt: new Date() },
  });
}

export async function declineSession(sessionId: string, userId: string) {
  const session = await getSessionOrThrow(sessionId);
  if (session.partnerId !== userId) throw AppError.forbidden("Only the invited partner can decline this session");
  if (session.status !== "PENDING") throw AppError.conflict("This session is no longer pending");

  return prisma.gameSession.update({ where: { id: sessionId }, data: { status: "DECLINED" } });
}

export async function getSessionDetail(sessionId: string, userId: string) {
  const session = await getSessionOrThrow(sessionId);
  assertParticipant(session, userId);

  const myResponses = await prisma.response.findMany({
    where: { sessionId, userId },
  });
  const myResponseMap = new Map(myResponses.map((r) => [r.kinkId, r]));

  const partnerId = session.initiatorId === userId ? session.partnerId : session.initiatorId;
  const partnerResponseCount = await prisma.response.count({ where: { sessionId, userId: partnerId } });

  const isInitiator = session.initiatorId === userId;
  // Sort by the order assigned once at creation, not a fresh shuffle - otherwise the deck
  // would jumble (and the "resume where I left off" position would drift) on every reload.
  const orderedItems = [...session.items].sort((a, b) => {
    const orderA = (isInitiator ? a.initiatorOrder : a.partnerOrder) ?? 0;
    const orderB = (isInitiator ? b.initiatorOrder : b.partnerOrder) ?? 0;
    return orderA - orderB;
  });

  return {
    id: session.id,
    status: session.status,
    itemCount: session.itemCount,
    isInitiator,
    createdAt: session.createdAt,
    acceptedAt: session.acceptedAt,
    completedAt: session.completedAt,
    items: orderedItems.map((item) => ({
      kinkId: item.kinkId,
      name: item.kink.name,
      description: item.kink.description,
      hasRoleVariant: item.kink.hasRoleVariant,
      roleA: item.kink.roleA ?? null,
      roleB: item.kink.roleB ?? null,
      myAnswer: myResponseMap.get(item.kinkId)?.answer ?? null,
      myRole: myResponseMap.get(item.kinkId)?.role ?? null,
    })),
    myProgress: myResponses.length,
    partnerProgress: partnerResponseCount,
  };
}

export async function submitResponse(
  sessionId: string,
  userId: string,
  input: { kinkId: string; answer: boolean; role?: ResponseRole },
) {
  const session = await getSessionOrThrow(sessionId);
  assertParticipant(session, userId);
  if (session.status !== "ACTIVE") throw AppError.conflict("This session is not currently active");

  const item = session.items.find((i) => i.kinkId === input.kinkId);
  if (!item) throw AppError.badRequest("That item is not part of this session");

  const alreadyAnswered = await prisma.response.findUnique({
    where: { sessionId_userId_kinkId: { sessionId, userId, kinkId: input.kinkId } },
  });
  if (alreadyAnswered) throw AppError.conflict("This item has already been answered and cannot be changed");

  const role = input.answer && item.kink.hasRoleVariant ? input.role ?? null : null;

  await prisma.response.create({
    data: { sessionId, userId, kinkId: input.kinkId, answer: input.answer, role },
  });

  await maybeCompleteSession(sessionId, session.itemCount);

  return getSessionDetail(sessionId, userId);
}

async function maybeCompleteSession(sessionId: string, itemCount: number) {
  const responses = await prisma.response.findMany({ where: { sessionId } });
  const byUser = new Map<string, number>();
  for (const r of responses) byUser.set(r.userId, (byUser.get(r.userId) ?? 0) + 1);

  const bothDone = [...byUser.values()].filter((count) => count >= itemCount).length >= 2;
  if (!bothDone) return;

  const session = await prisma.gameSession.findUnique({ where: { id: sessionId } });
  if (!session || session.status === "COMPLETED") return;

  const yesResponsesByKink = new Map<string, (ResponseRole | null)[]>();
  for (const r of responses) {
    if (!r.answer) continue;
    const roles = yesResponsesByKink.get(r.kinkId) ?? [];
    roles.push(r.role);
    yesResponsesByKink.set(r.kinkId, roles);
  }
  const matchedKinkIds = [...yesResponsesByKink.entries()]
    .filter(([, roles]) => roles.length >= 2 && rolesAreCompatible(roles[0]!, roles[1]!))
    .map(([kinkId]) => kinkId);

  await prisma.$transaction([
    prisma.gameSession.update({ where: { id: sessionId }, data: { status: "COMPLETED", completedAt: new Date() } }),
    ...matchedKinkIds.map((kinkId) =>
      prisma.match.upsert({
        where: { sessionId_kinkId: { sessionId, kinkId } },
        create: { sessionId, kinkId },
        update: {},
      }),
    ),
  ]);
}

export async function getSessionMatches(sessionId: string, userId: string) {
  const session = await getSessionOrThrow(sessionId);
  assertParticipant(session, userId);
  if (session.status !== "COMPLETED") throw AppError.conflict("This session has not finished yet");

  const matches = await prisma.match.findMany({
    where: { sessionId },
    include: { kink: { select: kinkSelect } },
  });

  const partnerId = session.initiatorId === userId ? session.partnerId : session.initiatorId;

  const responses = await prisma.response.findMany({
    where: { sessionId, kinkId: { in: matches.map((m) => m.kinkId) }, answer: true },
  });
  const rolesByKinkAndUser = new Map<string, Map<string, ResponseRole>>();
  for (const r of responses) {
    if (!r.role) continue;
    const byUser = rolesByKinkAndUser.get(r.kinkId) ?? new Map<string, ResponseRole>();
    byUser.set(r.userId, r.role);
    rolesByKinkAndUser.set(r.kinkId, byUser);
  }

  return matches.map((m) => {
    const byUser = rolesByKinkAndUser.get(m.kinkId);
    return {
      kinkId: m.kinkId,
      name: m.kink.name,
      description: m.kink.description,
      roleA: m.kink.roleA ?? null,
      roleB: m.kink.roleB ?? null,
      myRole: byUser?.get(userId) ?? null,
      partnerRole: byUser?.get(partnerId) ?? null,
    };
  });
}
