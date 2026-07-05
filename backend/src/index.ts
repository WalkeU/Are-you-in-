import { createApp } from "./app";
import { env } from "./config/env";
import { logger } from "./lib/logger";
import { prisma } from "./lib/prisma";
import { expireStaleSessions } from "./modules/sessions/sessions.service";

const app = createApp();

const server = app.listen(env.PORT, () => {
  logger.info(`Are You In? API listening on port ${env.PORT} (${env.NODE_ENV})`);
});

const EXPIRY_SWEEP_INTERVAL_MS = 30 * 60 * 1000;

async function sweepStaleSessions() {
  try {
    const count = await expireStaleSessions();
    if (count > 0) logger.info(`Expired ${count} session(s) stuck for over 12h`);
  } catch (err) {
    logger.error({ err }, "Failed to sweep stale sessions");
  }
}

void sweepStaleSessions();
const expirySweepTimer = setInterval(sweepStaleSessions, EXPIRY_SWEEP_INTERVAL_MS);
expirySweepTimer.unref();

async function shutdown(signal: string) {
  logger.info(`Received ${signal}, shutting down gracefully`);
  clearInterval(expirySweepTimer);
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
