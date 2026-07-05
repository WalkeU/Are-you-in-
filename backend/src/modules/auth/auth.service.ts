import { prisma } from "../../lib/prisma";
import { generateInviteCode } from "../../utils/inviteCode";
import { signAccessToken, signRefreshToken, verifyRefreshToken, hashToken, ttlToMs } from "../../utils/jwt";
import { env } from "../../config/env";
import { AppError } from "../../utils/errors";
import { cancelActiveSessionsForUser } from "../sessions/sessions.service";
import type { User } from "@prisma/client";

const MAX_INVITE_CODE_ATTEMPTS = 5;

export function toPublicUser(user: User) {
  return {
    id: user.id,
    name: user.name,
    inviteCode: user.inviteCode,
    partnerId: user.partnerId,
    createdAt: user.createdAt,
  };
}

async function createUserWithUniqueInviteCode(name: string): Promise<User> {
  for (let attempt = 0; attempt < MAX_INVITE_CODE_ATTEMPTS; attempt++) {
    try {
      return await prisma.user.create({
        data: { name, inviteCode: generateInviteCode() },
      });
    } catch (err: unknown) {
      const isUniqueViolation =
        typeof err === "object" && err !== null && "code" in err && (err as { code?: string }).code === "P2002";
      if (!isUniqueViolation || attempt === MAX_INVITE_CODE_ATTEMPTS - 1) throw err;
    }
  }
  throw new Error("Unreachable");
}

async function issueTokenPair(userId: string) {
  const tokenRecord = await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: "pending",
      expiresAt: new Date(Date.now() + ttlToMs(env.JWT_REFRESH_TTL)),
    },
  });

  const refreshToken = signRefreshToken(userId, tokenRecord.id);
  await prisma.refreshToken.update({
    where: { id: tokenRecord.id },
    data: { tokenHash: hashToken(refreshToken) },
  });

  const accessToken = signAccessToken(userId);
  return { accessToken, refreshToken };
}

export async function register(name: string) {
  const user = await createUserWithUniqueInviteCode(name);
  const tokens = await issueTokenPair(user.id);
  return { user: toPublicUser(user), ...tokens };
}

export async function pairWithInviteCode(currentUserId: string, inviteCode: string) {
  const [currentUser, targetUser] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: currentUserId } }),
    prisma.user.findUnique({ where: { inviteCode } }),
  ]);

  if (!targetUser) throw AppError.notFound("No user found with that invite code");
  if (targetUser.id === currentUser.id) throw AppError.badRequest("You cannot pair with yourself");
  if (currentUser.partnerId) throw AppError.conflict("You are already paired with a partner");
  if (targetUser.partnerId) throw AppError.conflict("That user is already paired with someone else");

  const [updatedCurrent] = await prisma.$transaction([
    prisma.user.update({ where: { id: currentUser.id }, data: { partnerId: targetUser.id } }),
    prisma.user.update({ where: { id: targetUser.id }, data: { partnerId: currentUser.id } }),
  ]);

  return toPublicUser(updatedCurrent);
}

export async function refreshTokens(refreshToken: string) {
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw AppError.unauthorized("Invalid or expired refresh token");
  }

  const record = await prisma.refreshToken.findUnique({ where: { id: payload.jti } });
  if (!record || record.revokedAt || record.expiresAt < new Date() || record.tokenHash !== hashToken(refreshToken)) {
    throw AppError.unauthorized("Refresh token has been revoked or expired");
  }

  await prisma.refreshToken.update({ where: { id: record.id }, data: { revokedAt: new Date() } });
  return issueTokenPair(record.userId);
}

/**
 * There's no "log back in" flow in this app (registration is the only entry point),
 * so logging out is already a point of no return for the account - this makes it the
 * de facto account-deletion action. Wipes this user's own answers and permanently
 * revokes their tokens, then anonymizes (rather than deletes) the User row itself,
 * since GameSession/Match rows are shared with the partner and must keep pointing at
 * a valid user for the partner's own history to keep working.
 */
async function wipeAccountData(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  await prisma.$transaction([
    prisma.response.deleteMany({ where: { userId } }),
    prisma.refreshToken.deleteMany({ where: { userId } }),
    ...(user.partnerId
      ? [prisma.user.update({ where: { id: user.partnerId }, data: { partnerId: null } })]
      : []),
    prisma.user.update({
      where: { id: userId },
      data: { name: "Törölt felhasználó", inviteCode: `deleted-${userId}`, partnerId: null },
    }),
  ]);
}

export async function logout(refreshToken: string) {
  try {
    const payload = verifyRefreshToken(refreshToken);
    // Don't leave the partner stuck waiting on someone who just walked away mid-round.
    await cancelActiveSessionsForUser(payload.sub);
    await wipeAccountData(payload.sub);
  } catch {
    // Already invalid/expired - logout is idempotent either way.
  }
}
