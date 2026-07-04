import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuth } from "../../middleware/auth";
import { listKinksHandler } from "./kinks.controller";

export const kinksRouter = Router();

kinksRouter.get("/", requireAuth, asyncHandler(listKinksHandler));
