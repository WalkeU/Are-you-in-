import type { Request, Response } from "express";
import * as authService from "./auth.service";

export async function registerHandler(req: Request, res: Response) {
  const { name } = req.body as { name: string };
  const result = await authService.register(name);
  res.status(201).json(result);
}

export async function pairHandler(req: Request, res: Response) {
  const { inviteCode } = req.body as { inviteCode: string };
  const user = await authService.pairWithInviteCode(req.userId!, inviteCode);
  res.status(200).json({ user });
}

export async function refreshHandler(req: Request, res: Response) {
  const { refreshToken } = req.body as { refreshToken: string };
  const tokens = await authService.refreshTokens(refreshToken);
  res.status(200).json(tokens);
}

export async function logoutHandler(req: Request, res: Response) {
  const { refreshToken } = req.body as { refreshToken: string };
  await authService.logout(refreshToken);
  res.status(204).send();
}
