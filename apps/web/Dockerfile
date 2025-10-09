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

# Install gettext for envsubst and curl for healthcheck
RUN apk add --no-cache gettext curl

# Create required directories and set permissions for the non-root 'nginx' user
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run /etc/nginx/conf.d

# Copy built static assets from the builder stage
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Copy the Nginx configuration template
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy and set permissions for the startup script
COPY --chmod=755 .github/docker/web-entrypoint.sh /docker-entrypoint.sh

# Expose the port defined by the PORT environment variable
ENV PORT=8080
EXPOSE 8080

# Health check to ensure Nginx is responsive on the root URL
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:${PORT}/ || exit 1

# THE KEY FIX IS HERE:
# The entrypoint script runs as root to create the config file.
# The script itself then switches to the 'nginx' user to run the server.
ENTRYPOINT ["/docker-entrypoint.sh"]

