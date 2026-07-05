# Are You In? — Backend API

Node.js/TypeScript REST API for the "Are You In?" couples preference-matching app.

## Stack

- Express 4 + TypeScript (strict mode)
- PostgreSQL via Prisma ORM
- JWT access + refresh tokens (refresh tokens are hashed at rest and rotated on use)
- Zod request validation, Helmet, CORS allowlist, per-IP rate limiting
- Pino structured logging
- Vitest + Supertest integration tests
- Multi-stage Docker build, docker-compose with Postgres

## Local development

Docker-backed workflow:

```bash
cp .env.example .env      # fill in real secrets before anything but local dev
docker compose -f docker-compose.dev.yml up -d --build
```

Native workflow:

```bash
cp .env.example .env      # fill in real secrets before anything but local dev
npm install
npm run prisma:migrate    # applies schema, creates migration on first run
npm run prisma:seed       # loads the kink/preference catalog
npm run dev                # tsx watch mode on $PORT (default 3000)
```

If you use the Docker-backed workflow, the API starts in a container and runs migrations
and seed automatically on startup. Keep `npm run dev` for a native watch loop only when
you're not using the containerized API.

## Production (containerized)

```bash
cp .env.example .env      # set strong JWT secrets + POSTGRES_PASSWORD
docker compose up -d --build
```

The `api` container runs `prisma migrate deploy` and seeds the catalog automatically on
startup before booting the server, so a fresh deploy is self-sufficient given only a `.env`
file. `GET /health` is wired up for the container `HEALTHCHECK` and for load balancer probes.

The production API is expected to be reachable at `https://rui.walkegabor.hu/api` (this is
hardcoded as the release-build base URL in the iOS app's `Core/Config.swift`). The
`docker-compose.yml` `api` service only publishes plain HTTP on `:3000` - a TLS-terminating
reverse proxy in front of it (owning port 443 for `rui.walkegabor.hu`) is required, since iOS
App Transport Security refuses plain HTTP for release builds. See `Caddyfile.example` for a
minimal Caddy config that auto-provisions the certificate; any reverse proxy works as long as
it forwards to the `api` container on port 3000. Once that's in place, set
`CORS_ORIGINS=https://rui.walkegabor.hu` in `.env` (only relevant for a future browser-based
client - the native app doesn't send an `Origin` header).

## Known local-path caveat

The parent folder name (`Are you in?`) contains a literal `?`. `tsx` and `vitest` (both
built on top of esbuild/vite-node - used by `npm run dev`, `npm run prisma:seed`, and
`npm test`) mis-resolve an internal source-map/module URL when any ancestor directory name
contains `?`, and fail immediately with an `ENOENT`/"Failed to load url" pointing at a
truncated path. This does **not** affect the Docker image (its `WORKDIR` is `/app`, with no
special characters), plain `tsc`/`node`, or CI (checkout paths won't contain `?`) - only
these dev-time tools, and only when this exact checkout lives under a `?`-containing path.
Verified locally by seeding + exercising the API through compiled plain JS (`tsc` + `node`,
no tsx) against a real Postgres instance - full auth/pairing/session/match/history flow
passes. If you hit the tsx/vitest error locally, either run everything through
`docker compose` (recommended, see above) or move/rename this checkout to a path without
`?`.

## Tests

Tests run against a real Postgres database (no mocking of the DB layer). Point
`backend/.env.test` at a disposable database (defaults to `areyouin_test` on the same
docker-compose Postgres instance), then:

```bash
npm test
```

The suite applies migrations, seeds the catalog, and exercises the full flow: register →
pair → create session → accept → answer → auto-complete → matches → history, including the
negative paths (self-pairing, unpaired session creation, immutable answers, missing auth).

## API overview

All endpoints are namespaced under `/api` and (except `/auth/register`, `/auth/refresh`,
`/auth/logout`) require `Authorization: Bearer <accessToken>`.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/auth/register` | Create a user, returns tokens + invite code |
| POST | `/auth/pair` | Link the caller's account with another user's invite code |
| POST | `/auth/refresh` | Rotate an access/refresh token pair |
| POST | `/auth/logout` | Revoke a refresh token |
| GET | `/me` | Current user profile + partner (if paired) |
| GET | `/kinks` | Full preference catalog |
| POST | `/sessions` | Initiator starts a new round (`itemCount`) |
| GET | `/sessions/pending` | Rounds awaiting my accept/decline |
| GET | `/sessions/active` | My in-progress (pending or active) round |
| GET | `/sessions/:id` | Round detail + my progress (never reveals partner's answers) |
| POST | `/sessions/:id/accept` \| `/decline` | Respond to an invite |
| POST | `/sessions/:id/responses` | Submit one answer (`kinkId`, `answer`, optional `role`) |
| GET | `/sessions/:id/matches` | Mutual matches once the round is `COMPLETED` |
| GET | `/history/my-responses` | My own answers across every completed round |
| GET | `/history/matches` | Every mutual match ever unlocked with my partner |

### Design notes that map to the product spec

- Each side sees the shared item set in an **independently randomized order**
  (`sessions.service.getSessionDetail` reshuffles per request instead of persisting one
  global order).
- Answers are **write-once**: `POST /sessions/:id/responses` returns `409 Conflict` on a
  repeat `kinkId`, matching "a már elmentett válaszok utólag nem módosíthatók."
  Non-participants get a scoped session view (their own answer only), never the partner's,
  until the round is `COMPLETED` and matches are computed server-side.
- A round auto-completes the moment both sides have answered every item; matches are
  computed once, transactionally, from mutual `answer: true` responses.
- Only one `PENDING`/`ACTIVE` round is allowed per couple at a time, so "bármelyik fél
  bármikor indíthat új játékmenetet" doesn't race two overlapping rounds.

### Extensibility

- `Kink` rows are seeded from `src/data/kinks.ts` by stable `key`, so the catalog can grow
  (new items, categories, i18n) without breaking existing `Response`/`Match` history.
- `role` is a first-class enum (`ROLE_A`/`ROLE_B`/`BOTH`) attached to `Response`, ready for
  richer compatibility scoring later.
- Refresh tokens are individually revocable (`RefreshToken` rows), which is what a future
  "log out other devices" or admin-revoke feature would build on.
- The module layout (`modules/<domain>/{routes,controller,service,schemas}`) is meant to
  scale to more domains (push notifications, real-time round updates via WebSocket, admin
  tooling) without restructuring existing ones.
