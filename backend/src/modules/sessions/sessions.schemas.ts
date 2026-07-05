import { z } from "zod";

export const createSessionSchema = z.object({
  itemCount: z.coerce.number().int().min(1).max(200),
  /** How hard the round should get, at most. Defaults to the mildest tier. */
  maxIntensity: z.coerce.number().int().min(1).max(3).default(1),
  /** When true, only draw from exactly `maxIntensity` instead of everything up to it. */
  exactIntensity: z.boolean().default(false),
});

export const sessionIdParamSchema = z.object({
  id: z.string().min(1),
});

export const submitResponseSchema = z.object({
  kinkId: z.string().min(1),
  answer: z.boolean(),
  role: z.enum(["ROLE_A", "ROLE_B", "BOTH"]).optional(),
});
