# Multi-stage Dockerfile for Adyela Web (Frontend)
# Build context should be the monorepo root.

# ==============================================================================
# Stage 1: Builder
# - Compiles production-ready static assets.
# ==============================================================================
FROM node:20-slim AS builder

RUN npm install -g pnpm@9
WORKDIR /app

COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY apps/web/package.json ./apps/web/
RUN pnpm install --frozen-lockfile --filter @adyela/web... --prod=false

COPY apps/web ./apps/web

ARG VITE_API_URL
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_JITSI_DOMAIN=meet.jit.si
ARG VITE_ENV=staging

RUN pnpm --filter @adyela/web build

# ==============================================================================
# Stage 2: Production
# - Final, lightweight, and secure image using Nginx to serve static files.
# ==============================================================================
FROM nginx:1.27-alpine AS production

# Instalar herramientas necesarias:
# gettext -> para 'envsubst' que usa el script de inicio.
# curl    -> para la verificación de salud (HEALTHCHECK).
# su-exec -> para cambiar de usuario de forma segura.
RUN apk add --no-cache gettext curl su-exec

# Crear directorios clave y dar permisos al usuario 'nginx'.
# Este es el paso crucial que soluciona los errores de "Permission denied".
RUN mkdir -p /var/log/nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /etc/nginx/conf.d

# Copiar los archivos estáticos compilados desde la etapa 'builder'.
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Copiar la configuración de Nginx como una plantilla.
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf.template

# Copiar el script de inicio y darle permisos de ejecución.
COPY --chmod=755 .github/docker/web-entrypoint.sh /docker-entrypoint.sh

# Definir y exponer el puerto que usará Cloud Run.
ENV PORT=8080
EXPOSE 8080

# Verificación de salud para que Cloud Run sepa que el contenedor está listo.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:${PORT}/ || exit 1

# Definir el script de inicio como el punto de entrada del contenedor.
ENTRYPOINT ["/docker-entrypoint.sh"]

