import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import pinoHttp from "pino-http";
import { env } from "./config/env";
import { logger } from "./lib/logger";
import { notFoundHandler, errorHandler } from "./middleware/errorHandler";
import { authRouter } from "./modules/auth/auth.routes";
import { usersRouter } from "./modules/users/users.routes";
import { kinksRouter } from "./modules/kinks/kinks.routes";
import { sessionsRouter } from "./modules/sessions/sessions.routes";
import { historyRouter } from "./modules/history/history.routes";
import { debugRouter } from "./modules/debug/debug.routes";

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
  app.set("trust proxy", 1);

  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigins.length > 0 ? env.corsOrigins : false,
      credentials: true,
    }),
  );
  app.use(express.json({ limit: "256kb" }));
  app.use(pinoHttp({ logger, autoLogging: !env.isTest }));

  app.use(
    "/api",
    rateLimit({
      windowMs: env.RATE_LIMIT_WINDOW_MS,
      max: env.RATE_LIMIT_MAX,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  app.get("/health", (_req, res) => {
    res.status(200).json({ status: "ok" });
  });

  // Dev-only dashboard for eyeballing users/sessions - never mounted in production.
  if (!env.isProduction) {
    app.use("/debug", debugRouter);
  }

  app.use("/api/auth", authRouter);
  app.use("/api/me", usersRouter);
  app.use("/api/kinks", kinksRouter);
  app.use("/api/sessions", sessionsRouter);
  app.use("/api/history", historyRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
