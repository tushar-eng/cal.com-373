# syntax = docker/dockerfile:1

# Multi-stage image for Cal.com Web (v3.7.x monorepo)

ARG NODE_VERSION=20.7.0
FROM node:${NODE_VERSION}-slim AS base

WORKDIR /app
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NEXT_TELEMETRY_DISABLED=1

# Make Yarn Berry available (and deterministic)
RUN corepack enable && corepack prepare yarn@3.6.4 --activate

# Common build deps for native modules
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential python-is-python3 pkg-config git ca-certificates openssl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# ---------- PRUNE STAGE ----------
FROM base AS pruner

# Only the files needed to compute the pruned graph
COPY package.json yarn.lock .yarnrc.yml turbo.json ./
# IMPORTANT: copy the Yarn Berry folder correctly (no leading slash)
COPY .yarn/ .yarn/
# If Turbo uses these during graph calc, include them too:
COPY apps/web/package.json apps/web/package.json
COPY packages ./packages

# Make Turbo faster & reproducible
ENV YARN_CACHE_FOLDER=.yarn/cache
RUN yarn config set nodeLinker node-modules && \
    yarn config set enableGlobalCache false && \
    yarn config set nmMode hardlinks-local && \
    yarn config set httpTimeout 1200000

# Produce a pruned dependency graph for the web app
RUN npx turbo prune --scope=@calcom/web --docker

# ---------- INSTALLER STAGE ----------
FROM base AS installer

WORKDIR /app

# Bring in the pruned manifests from /out
COPY --from=pruner /app/out/json/ ./
COPY --from=pruner /app/.yarn/ .yarn/
COPY --from=pruner /app/.yarnrc.yml ./

ENV YARN_CACHE_FOLDER=.yarn/cache
RUN yarn config set nodeLinker node-modules && \
    yarn config set enableGlobalCache false && \
    yarn config set nmMode hardlinks-local

# Install exactly what the pruned graph says
# (Use --immutable once things are green)
RUN yarn install --verbose

# ---------- BUILDER STAGE ----------
FROM installer AS builder

# Bring in the pruned source files
COPY --from=pruner /app/out/full/ ./

# Build-time env (can still be overridden with --build-arg)
ARG NEXTAUTH_SECRET=dev-build-secret-32chars-minimum
ARG CALENDSO_ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
ARG NEXTAUTH_URL=http://localhost:3000/api/auth
ARG NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
ARG EMAIL_FROM="Cal.com <no-reply@localhost>"
ARG DATABASE_URL="postgresql://placeholder:placeholder@localhost:5432/placeholder"

ENV NEXTAUTH_SECRET="${NEXTAUTH_SECRET}padding-to-ensure-32-characters"
ENV CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY}
ENV NEXTAUTH_URL=${NEXTAUTH_URL}
ENV NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL}
ENV EMAIL_FROM=${EMAIL_FROM}
ENV DATABASE_URL=${DATABASE_URL}

# Build the web app
RUN set -ex; \
  echo "Starting build process..." && \
  echo "NEXTAUTH_SECRET length: ${#NEXTAUTH_SECRET}" && \
  echo "NEXT_PUBLIC_WEBAPP_URL: $NEXT_PUBLIC_WEBAPP_URL" && \
  yarn turbo run build --filter=@calcom/web --verbose

# ---------- RUNTIME STAGE ----------
FROM node:${NODE_VERSION}-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# runtime needs openssl for Next.js/Node TLS
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy only runtime bits from the builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/turbo.json ./turbo.json

# Web app runtime assets
COPY --from=builder /app/apps/web/package.json ./apps/web/package.json
COPY --from=builder /app/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=builder /app/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/public ./apps/web/public

# Shared packages used at runtime (types/config/etc)
COPY --from=builder /app/packages/config ./packages/config
COPY --from=builder /app/packages/tsconfig ./packages/tsconfig
COPY --from=builder /app/packages/types ./packages/types

EXPOSE 80
CMD ["sh", "-lc", "yarn db-deploy && PORT=80 yarn workspace @calcom/web start"]
