import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { requireAuth } from "../../middleware/auth";
import { getMeHandler } from "./users.controller";

export const usersRouter = Router();

usersRouter.get("/", requireAuth, asyncHandler(getMeHandler));
