import type { Request, Response } from "express";
import { prisma } from "../../lib/prisma";

const RUNNING_STATUSES = new Set(["PENDING", "ACTIVE"]);

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function formatDate(date: Date | null): string {
  if (!date) return "–";
  return date.toISOString().replace("T", " ").slice(0, 19);
}

function statusBadge(status: string): string {
  const color = RUNNING_STATUSES.has(status) ? "#1a7f37" : "#6e7781";
  return `<span style="color:${color};font-weight:600">${escapeHtml(status)}</span>`;
}

export async function debugDashboardHandler(_req: Request, res: Response) {
  const [users, sessions] = await Promise.all([
    prisma.user.findMany({
      orderBy: { createdAt: "desc" },
      select: { id: true, name: true, inviteCode: true, partnerId: true, createdAt: true },
    }),
    prisma.gameSession.findMany({
      orderBy: { createdAt: "desc" },
      take: 100,
      include: {
        initiator: { select: { id: true, name: true } },
        partner: { select: { id: true, name: true } },
      },
    }),
  ]);

  const nameById = new Map(users.map((u) => [u.id, u.name]));
  const runningCount = sessions.filter((s) => RUNNING_STATUSES.has(s.status)).length;

  const userRows = users
    .map(
      (u) => `
      <tr>
        <td>${escapeHtml(u.name)}</td>
        <td><code>${escapeHtml(u.inviteCode)}</code></td>
        <td>${u.partnerId ? escapeHtml(nameById.get(u.partnerId) ?? u.partnerId) : "<em>nincs</em>"}</td>
        <td class="mono">${escapeHtml(u.id)}</td>
        <td>${formatDate(u.createdAt)}</td>
      </tr>`,
    )
    .join("");

  const sessionRows = sessions
    .map(
      (s) => `
      <tr${RUNNING_STATUSES.has(s.status) ? ' class="running"' : ""}>
        <td>${statusBadge(s.status)}</td>
        <td>${escapeHtml(s.initiator.name)}</td>
        <td>${escapeHtml(s.partner.name)}</td>
        <td>${s.itemCount}</td>
        <td>${formatDate(s.createdAt)}</td>
        <td>${formatDate(s.acceptedAt)}</td>
        <td>${formatDate(s.completedAt)}</td>
        <td class="mono">${escapeHtml(s.id)}</td>
      </tr>`,
    )
    .join("");

  const html = `<!doctype html>
<html lang="hu">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="5">
<title>Are You In? – Debug</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 2rem; background: #0d1117; color: #e6edf3; }
  h1 { font-size: 1.25rem; margin-bottom: 0.25rem; }
  .subtitle { color: #8b949e; margin-bottom: 1.5rem; font-size: 0.85rem; }
  .stat { display: inline-block; background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 0.5rem 1rem; margin-right: 0.75rem; margin-bottom: 1.5rem; }
  .stat strong { font-size: 1.1rem; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 2.5rem; font-size: 0.85rem; }
  th, td { text-align: left; padding: 0.4rem 0.6rem; border-bottom: 1px solid #21262d; }
  th { color: #8b949e; font-weight: 500; text-transform: uppercase; font-size: 0.7rem; letter-spacing: 0.03em; }
  tr.running { background: rgba(46, 160, 67, 0.08); }
  .mono { font-family: ui-monospace, SFMono-Regular, monospace; color: #8b949e; font-size: 0.75rem; }
  code { background: #161b22; padding: 0.1rem 0.35rem; border-radius: 4px; }
  em { color: #8b949e; font-style: normal; }
</style>
</head>
<body>
  <h1>Are You In? – Debug dashboard</h1>
  <div class="subtitle">Frissül 5 másodpercenként · ${formatDate(new Date())}</div>

  <div class="stat">Userek: <strong>${users.length}</strong></div>
  <div class="stat">Sessionök összesen: <strong>${sessions.length}</strong></div>
  <div class="stat">Futó session: <strong>${runningCount}</strong></div>

  <h2>Userek</h2>
  <table>
    <thead>
      <tr><th>Név</th><th>Meghívókód</th><th>Partner</th><th>ID</th><th>Regisztrált</th></tr>
    </thead>
    <tbody>${userRows || `<tr><td colspan="5"><em>nincs user</em></td></tr>`}</tbody>
  </table>

  <h2>Sessionök</h2>
  <table>
    <thead>
      <tr><th>Status</th><th>Kezdeményező</th><th>Partner</th><th>Db</th><th>Létrehozva</th><th>Elfogadva</th><th>Befejezve</th><th>ID</th></tr>
    </thead>
    <tbody>${sessionRows || `<tr><td colspan="8"><em>nincs session</em></td></tr>`}</tbody>
  </table>
</body>
</html>`;

  res.status(200).type("html").send(html);
}
