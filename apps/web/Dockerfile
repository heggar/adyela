# =====================
# Stage 1: Builder
# =====================
FROM node:20-slim AS builder


RUN npm install -g pnpm@9
WORKDIR /app


COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY apps/web/package.json ./apps/web/
RUN pnpm install --frozen-lockfile --filter @adyela/web... --prod=false


COPY . .
RUN pnpm --filter @adyela/web build


# =====================
# Stage 2: Runtime
# =====================
# FROM nginx:1.27-alpine AS production
FROM nginxinc/nginx-unprivileged:stable-alpine AS production

# 1) Subir a root para poder instalar paquetes
USER root
RUN apk add --no-cache gettext   # (para envsubst)

# 2) Copiar artefactos con ownership correcto para el usuario 101
COPY --from=builder --chown=101:101 /app/apps/web/dist/ /usr/share/nginx/html/
COPY --chown=101:101 apps/web/nginx.conf /etc/nginx/templates/default.conf.template
COPY --chown=101:101 web-entrypoint.sh /web-entrypoint.sh
RUN chmod +x /web-entrypoint.sh

# 3) Volver a usuario no-root (que es como corre esta imagen)
USER 101
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/web-entrypoint.sh"]