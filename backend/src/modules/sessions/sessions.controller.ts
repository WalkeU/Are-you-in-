import type { Request, Response } from "express";
import * as sessionsService from "./sessions.service";

export async function createSessionHandler(req: Request, res: Response) {
  const { itemCount } = req.body as { itemCount: number };
  const session = await sessionsService.createSession(req.userId!, itemCount);
  res.status(201).json({ session });
}

export async function listPendingHandler(req: Request, res: Response) {
  const sessions = await sessionsService.listPendingSessions(req.userId!);
  res.status(200).json({ sessions });
}

export async function listActiveHandler(req: Request, res: Response) {
  const sessions = await sessionsService.listActiveSessions(req.userId!);
  res.status(200).json({ sessions });
}

export async function getSessionHandler(req: Request, res: Response) {
  const detail = await sessionsService.getSessionDetail(req.params.id!, req.userId!);
  res.status(200).json({ session: detail });
}

export async function acceptSessionHandler(req: Request, res: Response) {
  const session = await sessionsService.acceptSession(req.params.id!, req.userId!);
  res.status(200).json({ session });
}

export async function declineSessionHandler(req: Request, res: Response) {
  const session = await sessionsService.declineSession(req.params.id!, req.userId!);
  res.status(200).json({ session });
}

export async function submitResponseHandler(req: Request, res: Response) {
  const detail = await sessionsService.submitResponse(req.params.id!, req.userId!, req.body);
  res.status(201).json({ session: detail });
}

export async function getMatchesHandler(req: Request, res: Response) {
  const matches = await sessionsService.getSessionMatches(req.params.id!, req.userId!);
  res.status(200).json({ matches });
}
