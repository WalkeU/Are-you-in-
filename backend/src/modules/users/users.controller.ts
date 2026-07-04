import type { Request, Response } from "express";
import { prisma } from "../../lib/prisma";
import { AppError } from "../../utils/errors";
import { toPublicUser } from "../auth/auth.service";

export async function getMeHandler(req: Request, res: Response) {
  const user = await prisma.user.findUnique({
    where: { id: req.userId! },
    include: { partner: true },
  });
  if (!user) throw AppError.notFound("User not found");

  res.status(200).json({
    user: toPublicUser(user),
    partner: user.partner ? { id: user.partner.id, name: user.partner.name } : null,
  });
}
