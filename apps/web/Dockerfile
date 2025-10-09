# Multi-stage Dockerfile for Adyela Web (Frontend)
# Build context should be the monorepo root.

# ==============================================================================
# Stage 1: Builder
# - Compiles production-ready static assets.
# - Optimized for caching.
# ==============================================================================
FROM node:20-slim AS builder

# Install pnpm globally
RUN npm install -g pnpm@9

WORKDIR /app

# Copy dependency manifests first to leverage Docker layer caching
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY apps/web/package.json ./apps/web/

# Install production dependencies for the web workspace
# Using --prod=false is correct as build tools are often in devDependencies
RUN pnpm install --frozen-lockfile --filter @adyela/web... --prod=false

# Copy the rest of the web app source code
COPY apps/web ./apps/web

# Build arguments for Vite environment variables (can be passed during `docker build`)
ARG VITE_API_URL
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_JITSI_DOMAIN=meet.jit.si
ARG VITE_ENV=staging

# Build the application
RUN pnpm --filter @adyela/web build

# ==============================================================================
# Stage 2: Production
# - Final, lightweight, and secure image using Nginx to serve static files.
# ==============================================================================
FROM nginx:1.27-alpine AS production

# Install gettext for `envsubst` utility and remove cache
RUN apk add --no-cache gettext

# Use a non-root user for security
# Nginx automatically creates an 'nginx' user. We will use it.
# Create directories for Nginx and give ownership to the nginx user.
RUN mkdir -p /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx

# Copy built static assets from the builder stage
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Copy the Nginx configuration template
# This template will be processed at container startup.
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy and set permissions for the startup script
COPY --chmod=755 .github/docker/web-entrypoint.sh /docker-entrypoint.sh

# Cambia al usuario no-root
USER nginx

# Expone el puerto (Cloud Run usará esto)
ENV PORT=8080
EXPOSE 8080

# Verificación de salud
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:${PORT}/ || exit 1

# El script de entrada configurará e iniciará Nginx
CMD ["/docker-entrypoint.sh"]