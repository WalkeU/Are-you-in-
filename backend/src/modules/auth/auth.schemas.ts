import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().trim().min(1, "Name is required").max(50, "Name must be 50 characters or fewer"),
});

export const pairSchema = z.object({
  inviteCode: z.string().trim().min(1).max(20).toUpperCase(),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const logoutSchema = z.object({
  refreshToken: z.string().min(1),
});
