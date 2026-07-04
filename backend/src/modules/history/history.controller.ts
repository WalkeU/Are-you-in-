import type { Request, Response } from "express";
import { prisma } from "../../lib/prisma";

export async function myResponsesHandler(req: Request, res: Response) {
  const responses = await prisma.response.findMany({
    where: { userId: req.userId!, session: { status: "COMPLETED" } },
    include: { kink: { select: { id: true, name: true, description: true, hasRoleVariant: true } } },
    orderBy: { createdAt: "desc" },
  });

  res.status(200).json({
    responses: responses.map((r) => ({
      sessionId: r.sessionId,
      kinkId: r.kinkId,
      name: r.kink.name,
      description: r.kink.description,
      answer: r.answer,
      role: r.role,
      answeredAt: r.createdAt,
    })),
  });
}

export async function myMatchesHandler(req: Request, res: Response) {
  const userId = req.userId!;
  const matches = await prisma.match.findMany({
    where: { session: { status: "COMPLETED", OR: [{ initiatorId: userId }, { partnerId: userId }] } },
    include: { kink: { select: { id: true, name: true, description: true } } },
    orderBy: { createdAt: "asc" },
  });

  const dedupedByKink = new Map<string, (typeof matches)[number]>();
  for (const m of matches) {
    if (!dedupedByKink.has(m.kinkId)) dedupedByKink.set(m.kinkId, m);
  }

  res.status(200).json({
    matches: [...dedupedByKink.values()].map((m) => ({
      kinkId: m.kinkId,
      name: m.kink.name,
      description: m.kink.description,
      sessionId: m.sessionId,
      matchedAt: m.createdAt,
    })),
  });
}
