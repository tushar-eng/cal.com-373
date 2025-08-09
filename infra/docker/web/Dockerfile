# syntax = docker/dockerfile:1
ARG NODE_VERSION=20.7.0
FROM node:${NODE_VERSION}-slim as build

WORKDIR /app
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096" NEXT_TELEMETRY_DISABLED=1
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential python-is-python3 pkg-config git ca-certificates openssl \
  && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN corepack enable && corepack prepare yarn@3.6.4 --activate

COPY package.json yarn.lock .yarnrc.yml turbo.json ./
COPY .yarn/ .yarn/
COPY apps apps
COPY packages packages
# (copy any other roots Cal/web needs: playwright config, etc.)
COPY . .

ENV YARN_CACHE_FOLDER=.yarn/cache PRISMA_SKIP_POSTINSTALL_GENERATE=1
RUN yarn config set nodeLinker node-modules && \
    yarn config set enableGlobalCache false && \
    yarn config set nmMode hardlinks-local && \
    yarn install --inline-builds --verbose

# now generate prisma + build
RUN yarn workspaces foreach -A -t exec -- prisma generate || true
RUN yarn turbo run build --filter=@calcom/web --verbose

FROM node:${NODE_VERSION}-slim as runner
WORKDIR /app
RUN apt-get update -qq && apt-get install -y --no-install-recommends openssl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1

# copy just what runtime needs
COPY --from=build /app/package.json /app/yarn.lock /app/turbo.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps/web/.next ./apps/web/.next
COPY --from=build /app/apps/web/public ./apps/web/public
COPY --from=build /app/apps/web/next*.js ./apps/web/
COPY --from=build /app/apps/web/package.json ./apps/web/package.json
COPY --from=build /app/packages/config ./packages/config
COPY --from=build /app/packages/tsconfig ./packages/tsconfig
COPY --from=build /app/packages/types ./packages/types

EXPOSE 80
CMD ["sh","-lc","yarn db-deploy && PORT=80 yarn workspace @calcom/web start"]
