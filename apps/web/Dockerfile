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
FROM nginx:1.27-alpine AS production

# gettext para envsubst (si lo usas)
RUN apk add --no-cache gettext

# Usuario no-root y permisos
RUN adduser -D -H -u 1001 app \
  && mkdir -p /var/cache/nginx /var/run/nginx /etc/nginx/conf.d \
  && chown -R app:app /var/cache/nginx /var/run/nginx /var/log/nginx /etc/nginx /usr/share/nginx/html

COPY --from=builder /app/apps/web/dist/ /usr/share/nginx/html/
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf.template
# Copy and set permissions for the startup script
COPY --chmod=755 .github/docker/web-entrypoint.sh /web-entrypoint.sh

RUN chmod +x /web-entrypoint.sh

USER 1001
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/web-entrypoint.sh"]