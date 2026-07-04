import { z } from "zod";

export const createSessionSchema = z.object({
  itemCount: z.coerce.number().int().min(1).max(200),
});

export const sessionIdParamSchema = z.object({
  id: z.string().min(1),
});

export const submitResponseSchema = z.object({
  kinkId: z.string().min(1),
  answer: z.boolean(),
  role: z.enum(["GIVE", "RECEIVE", "BOTH"]).optional(),
});
