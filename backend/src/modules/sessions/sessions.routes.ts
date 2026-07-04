import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { validate } from "../../middleware/validate";
import { requireAuth } from "../../middleware/auth";
import { createSessionSchema, sessionIdParamSchema, submitResponseSchema } from "./sessions.schemas";
import {
  createSessionHandler,
  listPendingHandler,
  listActiveHandler,
  getSessionHandler,
  acceptSessionHandler,
  declineSessionHandler,
  submitResponseHandler,
  getMatchesHandler,
} from "./sessions.controller";

export const sessionsRouter = Router();

sessionsRouter.use(requireAuth);

sessionsRouter.post("/", validate({ body: createSessionSchema }), asyncHandler(createSessionHandler));
sessionsRouter.get("/pending", asyncHandler(listPendingHandler));
sessionsRouter.get("/active", asyncHandler(listActiveHandler));
sessionsRouter.get("/:id", validate({ params: sessionIdParamSchema }), asyncHandler(getSessionHandler));
sessionsRouter.post("/:id/accept", validate({ params: sessionIdParamSchema }), asyncHandler(acceptSessionHandler));
sessionsRouter.post("/:id/decline", validate({ params: sessionIdParamSchema }), asyncHandler(declineSessionHandler));
sessionsRouter.post(
  "/:id/responses",
  validate({ params: sessionIdParamSchema, body: submitResponseSchema }),
  asyncHandler(submitResponseHandler),
);
sessionsRouter.get("/:id/matches", validate({ params: sessionIdParamSchema }), asyncHandler(getMatchesHandler));
