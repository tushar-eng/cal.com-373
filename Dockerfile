# syntax = docker/dockerfile:1

# Multi-stage image for Cal.com API (v3.7.x monorepo)
# Defaults to building and running @calcom/api on port 80 for EasyPanel

ARG NODE_VERSION=20.7.0
FROM node:${NODE_VERSION}-slim as base

WORKDIR /app
ENV NODE_ENV=production

# ----- Build stage -----
FROM base as build

# Copy monorepo files needed for pruning/install/build
COPY package.json yarn.lock .yarnrc.yml playwright.config.ts turbo.json git-init.sh git-setup.sh ./
COPY /.yarn ./.yarn
COPY ./apps/api ./apps/api
COPY ./packages ./packages
# Include web temporarily for shared config/locales used by API responses
COPY ./apps/web ./apps/web

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential openssl pkg-config python-is-python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    yarn config set httpTimeout 1200000 && \
    npx turbo prune --scope=@calcom/web --docker && \
    npx turbo prune --scope=@calcom/api --docker && \
    yarn install && \
    yarn turbo run build --filter=@calcom/api

# ----- Runtime stage -----
FROM base
WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built output and minimal runtime deps
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps/api/package.json ./apps/api/package.json
COPY --from=build /app/apps/api/next-i18next.config.js ./apps/api/next-i18next.config.js
COPY --from=build /app/apps/api/next.config.js ./apps/api/next.config.js
COPY --from=build /app/apps/api/tsconfig.json ./apps/api/tsconfig.json
COPY --from=build /app/apps/api/.next ./apps/api/.next
COPY --from=build /app/apps/api/.turbo ./apps/api/.turbo
COPY --from=build /app/turbo.json ./turbo.json
COPY --from=build /app/yarn.lock ./yarn.lock
COPY --from=build /app/packages/config ./packages/config
COPY --from=build /app/packages/tsconfig ./packages/tsconfig
COPY --from=build /app/packages/types ./packages/types
COPY --from=build /app/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=build /app/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=build /app/apps/web/public/static/locales ./apps/web/public/static/locales
COPY --from=build /app/apps/web/package.json ./apps/web/package.json

# EasyPanel expects a listening service; expose port 80 (API uses PORT=80)
EXPOSE 80

# Start API
CMD ["yarn", "workspace", "@calcom/api", "docker-start-api"]


