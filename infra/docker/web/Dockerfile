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

# Set build-time environment variables with defaults
# These can be overridden with --build-arg during docker build
ARG NEXTAUTH_SECRET=dev-build-secret-32chars-minimum
ARG CALENDSO_ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
ARG NEXTAUTH_URL=http://localhost:3000/api/auth
ARG NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
ARG EMAIL_FROM="Cal.com <no-reply@localhost>"
ARG DATABASE_URL="postgresql://placeholder:placeholder@localhost:5432/placeholder"

# Ensure NEXTAUTH_SECRET is at least 32 characters
ENV NEXTAUTH_SECRET="${NEXTAUTH_SECRET}padding-to-ensure-32-characters"
ENV CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY}
ENV NEXTAUTH_URL=${NEXTAUTH_URL}
ENV NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL}
ENV EMAIL_FROM=${EMAIL_FROM}
ENV DATABASE_URL=${DATABASE_URL}

# Enable Yarn Berry via Corepack (Node >=16 ships Corepack, but it's disabled by default)
RUN corepack enable

RUN set -eux; \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential openssl pkg-config python-is-python3 git ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install dependencies (Yarn Berry)
ENV YARN_ENABLE_GLOBAL_CACHE=1
ENV YARN_NM_MODE=hardlinks-local
RUN yarn config set httpTimeout 1200000 && \
    yarn install --immutable

# Build the web application with verbose logging
RUN set -ex; \
    echo "Starting build process..." && \
    echo "NEXTAUTH_SECRET length: ${#NEXTAUTH_SECRET}" && \
    echo "NEXT_PUBLIC_WEBAPP_URL: $NEXT_PUBLIC_WEBAPP_URL" && \
    yarn turbo run build --filter=@calcom/web --verbose

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


