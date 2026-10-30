#=======================
# Stage 1: Dependencies
#=======================

ARG NODE_VERSION=24-alpine3.23

FROM node:${NODE_VERSION} AS dependencies

WORKDIR /app

COPY package.json pnpm*.yaml ./

RUN corepack enable pnpm && corepack prepare pnpm@11.24.0 --activate

RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store/.next/cache \
pnpm install --frozen-lockfile

#=======================
# Stage 2: Builder
#=======================

FROM dependencies AS builder

WORKDIR /app

COPY . .

RUN pnpm build

#=======================
# Stage 3: Runner
#=======================

FROM node:${NODE_VERSION} AS runner

WORKDIR /app

USER node

COPY --from=builder --chown=node:node ./app/.next/standalone ./
COPY --from=builder --chown=node:node ./app/.next/static ./.next/static
COPY --from=builder --chown=node:node ./app/public ./public

EXPOSE 3000

CMD [ "node", "server.js" ]