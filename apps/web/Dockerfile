# =====================
# Stage 1: Builder
# =====================
FROM node:20-slim AS builder

# Accept build arguments for environment variables
ARG VITE_API_BASE_URL
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_JITSI_DOMAIN
ARG VITE_ENV

# Set environment variables for the build
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY
ENV VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID
ENV VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN
ENV VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET
ENV VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID
ENV VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID
ENV VITE_JITSI_DOMAIN=$VITE_JITSI_DOMAIN
ENV VITE_ENV=$VITE_ENV

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
COPY --chown=101:101 .github/docker/web-entrypoint.sh /web-entrypoint.sh
RUN chmod +x /web-entrypoint.sh

# 3) Volver a usuario no-root (que es como corre esta imagen)
USER 101
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/web-entrypoint.sh"]