# --- deps: install all deps once, cached across build/runtime stages ---
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# --- build: compile TypeScript + generate Prisma client ---
FROM node:20-alpine AS build
RUN apk add --no-cache openssl
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build
# Compile the seed script to plain JS too - the runtime image has no dev deps (no tsx),
# so seeding in production can't rely on ts-execution the way `npm run prisma:seed` does locally.
RUN npx tsc --outDir dist-seed --rootDir . --module commonjs --target ES2022 \
  --esModuleInterop --skipLibCheck --resolveJsonModule prisma/seed.ts src/types/express.d.ts

# --- prod deps only ---
FROM node:20-alpine AS prod-deps
RUN apk add --no-cache openssl
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY prisma ./prisma
RUN npx prisma generate

# --- runtime image ---
FROM node:20-alpine AS runtime
ENV NODE_ENV=production
RUN apk add --no-cache openssl
WORKDIR /app

RUN addgroup -S nodejs && adduser -S nodejs -G nodejs

COPY --from=prod-deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --from=build --chown=nodejs:nodejs /app/dist-seed ./dist-seed
COPY --chown=nodejs:nodejs prisma ./prisma
COPY --chown=nodejs:nodejs package.json ./

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["sh", "-c", "npx prisma migrate deploy && node dist-seed/prisma/seed.js && node dist/index.js"]
