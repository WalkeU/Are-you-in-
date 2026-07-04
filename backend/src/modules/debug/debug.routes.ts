import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { debugDashboardHandler } from "./debug.controller";

export const debugRouter = Router();

debugRouter.get("/", asyncHandler(debugDashboardHandler));
