import type { Request, Response } from "express";
import { prisma } from "../../lib/prisma";

export async function listKinksHandler(_req: Request, res: Response) {
  const kinks = await prisma.kink.findMany({
    orderBy: { order: "asc" },
    select: { id: true, name: true, description: true, hasRoleVariant: true, intensity: true },
  });
  res.status(200).json({ kinks });
}
