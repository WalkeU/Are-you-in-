import { Router } from "express";
import { asyncHandler } from "../../utils/asyncHandler";
import { validate } from "../../middleware/validate";
import { requireAuth } from "../../middleware/auth";
import { registerSchema, pairSchema, refreshSchema, logoutSchema } from "./auth.schemas";
import { registerHandler, pairHandler, refreshHandler, logoutHandler } from "./auth.controller";

export const authRouter = Router();

authRouter.post("/register", validate({ body: registerSchema }), asyncHandler(registerHandler));
authRouter.post("/pair", requireAuth, validate({ body: pairSchema }), asyncHandler(pairHandler));
authRouter.post("/refresh", validate({ body: refreshSchema }), asyncHandler(refreshHandler));
authRouter.post("/logout", validate({ body: logoutSchema }), asyncHandler(logoutHandler));
