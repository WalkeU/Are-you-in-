import { execSync } from "node:child_process";
import path from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import request from "supertest";

beforeAll(() => {
  const cwd = path.resolve(__dirname, "..");
  execSync("npx prisma migrate deploy", { cwd, env: process.env, stdio: "inherit" });
  execSync("npx prisma db seed", { cwd, env: process.env, stdio: "inherit" });
});

async function loadApp() {
  const { createApp } = await import("../src/app");
  return createApp();
}

async function cleanDb() {
  const { prisma } = await import("../src/lib/prisma");
  await prisma.match.deleteMany();
  await prisma.response.deleteMany();
  await prisma.gameSessionItem.deleteMany();
  await prisma.gameSession.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();
}

afterAll(async () => {
  const { prisma } = await import("../src/lib/prisma");
  await cleanDb();
  await prisma.$disconnect();
});

describe("Are You In? core flow", () => {
  it("registers, pairs, plays a session and surfaces mutual matches only", async () => {
    await cleanDb();
    const app = await loadApp();

    const aliceRes = await request(app).post("/api/auth/register").send({ name: "Alice" });
    expect(aliceRes.status).toBe(201);
    const alice = aliceRes.body;

    const bobRes = await request(app).post("/api/auth/register").send({ name: "Bob" });
    expect(bobRes.status).toBe(201);
    const bob = bobRes.body;

    const pairRes = await request(app)
      .post("/api/auth/pair")
      .set("Authorization", `Bearer ${alice.accessToken}`)
      .send({ inviteCode: bob.user.inviteCode });
    expect(pairRes.status).toBe(200);
    expect(pairRes.body.user.partnerId).toBe(bob.user.id);

    const meRes = await request(app).get("/api/me").set("Authorization", `Bearer ${bob.accessToken}`);
    expect(meRes.status).toBe(200);
    expect(meRes.body.partner.id).toBe(alice.user.id);

    const kinksRes = await request(app).get("/api/kinks").set("Authorization", `Bearer ${alice.accessToken}`);
    expect(kinksRes.status).toBe(200);
    expect(kinksRes.body.kinks.length).toBeGreaterThan(50);

    const createRes = await request(app)
      .post("/api/sessions")
      .set("Authorization", `Bearer ${alice.accessToken}`)
      .send({ itemCount: 5 });
    expect(createRes.status).toBe(201);
    const sessionId = createRes.body.session.id;
    const itemIds: string[] = createRes.body.session.items.map((i: { kinkId: string }) => i.kinkId);
    expect(itemIds).toHaveLength(5);

    const pendingRes = await request(app)
      .get("/api/sessions/pending")
      .set("Authorization", `Bearer ${bob.accessToken}`);
    expect(pendingRes.body.sessions.map((s: { id: string }) => s.id)).toContain(sessionId);

    const acceptRes = await request(app)
      .post(`/api/sessions/${sessionId}/accept`)
      .set("Authorization", `Bearer ${bob.accessToken}`);
    expect(acceptRes.status).toBe(200);
    expect(acceptRes.body.session.status).toBe("ACTIVE");

    // Alice says yes to everything, Bob says yes only to the first item -> exactly one mutual match.
    for (const kinkId of itemIds) {
      const res = await request(app)
        .post(`/api/sessions/${sessionId}/responses`)
        .set("Authorization", `Bearer ${alice.accessToken}`)
        .send({ kinkId, answer: true });
      expect(res.status).toBe(201);
    }

    for (const [index, kinkId] of itemIds.entries()) {
      const res = await request(app)
        .post(`/api/sessions/${sessionId}/responses`)
        .set("Authorization", `Bearer ${bob.accessToken}`)
        .send({ kinkId, answer: index === 0 });
      expect(res.status).toBe(201);
    }

    const finalDetail = await request(app)
      .get(`/api/sessions/${sessionId}`)
      .set("Authorization", `Bearer ${alice.accessToken}`);
    expect(finalDetail.body.session.status).toBe("COMPLETED");

    const matchesRes = await request(app)
      .get(`/api/sessions/${sessionId}/matches`)
      .set("Authorization", `Bearer ${bob.accessToken}`);
    expect(matchesRes.status).toBe(200);
    expect(matchesRes.body.matches).toHaveLength(1);
    expect(matchesRes.body.matches[0].kinkId).toBe(itemIds[0]);

    // A duplicate answer to an already-answered item must be rejected - answers are immutable.
    const duplicateRes = await request(app)
      .post(`/api/sessions/${sessionId}/responses`)
      .set("Authorization", `Bearer ${alice.accessToken}`)
      .send({ kinkId: itemIds[0], answer: true });
    expect(duplicateRes.status).toBe(409);

    const historyRes = await request(app)
      .get("/api/history/matches")
      .set("Authorization", `Bearer ${alice.accessToken}`);
    expect(historyRes.body.matches).toHaveLength(1);

    const myResponsesRes = await request(app)
      .get("/api/history/my-responses")
      .set("Authorization", `Bearer ${bob.accessToken}`);
    expect(myResponsesRes.body.responses).toHaveLength(5);
  });

  it("rejects pairing with yourself and starting a session while unpaired", async () => {
    await cleanDb();
    const app = await loadApp();

    const soloRes = await request(app).post("/api/auth/register").send({ name: "Solo" });
    const solo = soloRes.body;

    const selfPairRes = await request(app)
      .post("/api/auth/pair")
      .set("Authorization", `Bearer ${solo.accessToken}`)
      .send({ inviteCode: solo.user.inviteCode });
    expect(selfPairRes.status).toBe(400);

    const sessionRes = await request(app)
      .post("/api/sessions")
      .set("Authorization", `Bearer ${solo.accessToken}`)
      .send({ itemCount: 3 });
    expect(sessionRes.status).toBe(400);
  });

  it("rejects requests without a valid access token", async () => {
    const app = await loadApp();
    const res = await request(app).get("/api/me");
    expect(res.status).toBe(401);
  });
});
