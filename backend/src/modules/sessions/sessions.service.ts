import { prisma } from "../../lib/prisma";
import { AppError } from "../../utils/errors";
import { shuffle } from "../../utils/shuffle";
import type { ResponseRole } from "@prisma/client";

const kinkSelect = { id: true, name: true, description: true, hasRoleVariant: true } as const;

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

export async function createSession(initiatorId: string, itemCount: number) {
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

  const totalKinks = await prisma.kink.count();
  if (totalKinks === 0) throw AppError.badRequest("Kink catalog is empty; run the database seed first");
  const clampedCount = Math.min(itemCount, totalKinks);

  const allKinkIds = await prisma.kink.findMany({ select: { id: true } });
  const chosenIds = shuffle(allKinkIds).slice(0, clampedCount);

  const session = await prisma.gameSession.create({
    data: {
      initiatorId,
      partnerId: initiator.partnerId,
      itemCount: clampedCount,
      status: "PENDING",
      items: { create: chosenIds.map((k) => ({ kinkId: k.id })) },
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

  return {
    id: session.id,
    status: session.status,
    itemCount: session.itemCount,
    isInitiator: session.initiatorId === userId,
    createdAt: session.createdAt,
    acceptedAt: session.acceptedAt,
    completedAt: session.completedAt,
    items: shuffle(session.items).map((item) => ({
      kinkId: item.kinkId,
      name: item.kink.name,
      description: item.kink.description,
      hasRoleVariant: item.kink.hasRoleVariant,
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

  const yesByKink = new Map<string, number>();
  for (const r of responses) {
    if (r.answer) yesByKink.set(r.kinkId, (yesByKink.get(r.kinkId) ?? 0) + 1);
  }
  const matchedKinkIds = [...yesByKink.entries()].filter(([, count]) => count >= 2).map(([kinkId]) => kinkId);

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
      myRole: byUser?.get(userId) ?? null,
      partnerRole: byUser?.get(partnerId) ?? null,
    };
  });
}
