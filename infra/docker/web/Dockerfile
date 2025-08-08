# syntax = docker/dockerfile:1

# Multi-stage image for Cal.com Web (v3.7.x monorepo)

ARG NODE_VERSION=20.7.0
FROM node:${NODE_VERSION}-slim as base

WORKDIR /app
ENV NODE_ENV=production
# Global defaults for memory/telemetry
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NEXT_TELEMETRY_DISABLED=1

# ----- Build stage -----
FROM base as build

# Copy monorepo files needed for pruning/install/build
COPY package.json yarn.lock .yarnrc.yml playwright.config.ts turbo.json git-init.sh git-setup.sh ./
COPY /.yarn ./.yarn
COPY ./apps/web ./apps/web
COPY ./packages ./packages

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential openssl pkg-config python-is-python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    yarn config set httpTimeout 1200000 && \
    npx turbo prune --scope=@calcom/web --docker && \
    yarn install && \
    yarn turbo run build --filter=@calcom/web

# ----- Runtime stage -----
FROM base
WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built output and minimal runtime deps
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/turbo.json ./turbo.json
COPY --from=build /app/yarn.lock ./yarn.lock

# Web app runtime assets
COPY --from=build /app/apps/web/package.json ./apps/web/package.json
COPY --from=build /app/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=build /app/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=build /app/apps/web/.next ./apps/web/.next
COPY --from=build /app/apps/web/public ./apps/web/public

# Some shared packages config (used by runtime)
COPY --from=build /app/packages/config ./packages/config
COPY --from=build /app/packages/tsconfig ./packages/tsconfig
COPY --from=build /app/packages/types ./packages/types

# Expose port 80 for EasyPanel
EXPOSE 80

# Run DB migrations, then start web
CMD ["sh", "-lc", "yarn db-deploy && PORT=80 yarn workspace @calcom/web start"]


