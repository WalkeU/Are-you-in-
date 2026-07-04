import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuth } from "../../middleware/auth";
import { myResponsesHandler, myMatchesHandler } from "./history.controller";

export const historyRouter = Router();

historyRouter.use(requireAuth);
historyRouter.get("/my-responses", asyncHandler(myResponsesHandler));
historyRouter.get("/matches", asyncHandler(myMatchesHandler));
