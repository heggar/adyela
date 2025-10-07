# Multi-stage Dockerfile for Adyela Web
# Build context should be the monorepo root

# Development stage - for local development with HMR
FROM node:20-slim AS development

# Install pnpm
RUN npm install -g pnpm@9

WORKDIR /app

# Copy monorepo workspace files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# Copy web app package.json
COPY apps/web/package.json ./apps/web/

# Install ALL dependencies (including dev)
# Use --no-frozen-lockfile for development to allow lock file creation
RUN pnpm install --no-frozen-lockfile --filter @adyela/web...

# Set working directory to web app
WORKDIR /app/apps/web

# Code will be mounted as volume in docker-compose
# This allows Hot Module Replacement (HMR) during development

EXPOSE 3000 5173

# Default command (can be overridden in docker-compose)
CMD ["pnpm", "dev", "--host", "0.0.0.0", "--port", "3000"]

# Builder stage - build the production app
FROM node:20-slim AS builder

RUN npm install -g pnpm@9

WORKDIR /app

# Copy monorepo workspace files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# Copy web app files
COPY apps/web ./apps/web

# Install dependencies (production only)
RUN pnpm install --frozen-lockfile --filter @adyela/web... --prod=false

# Build args for Vite environment variables
ARG VITE_API_URL
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_JITSI_DOMAIN=meet.jit.si
ARG VITE_ENV=staging

# Set as environment variables for build
ENV VITE_API_URL=$VITE_API_URL \
    VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY \
    VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID \
    VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN \
    VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET \
    VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID \
    VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID \
    VITE_JITSI_DOMAIN=$VITE_JITSI_DOMAIN \
    VITE_ENV=$VITE_ENV

# Build the application
RUN pnpm --filter @adyela/web build

# Production stage - serve the built app
FROM nginx:1.27-alpine AS production

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Set environment variable for port (Cloud Run compatibility)
ENV PORT=8080

# Remove default nginx configs
RUN rm -f /etc/nginx/conf.d/*

# Copy nginx configuration template
COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy built files from builder
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Create startup script
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo 'echo "Processing nginx template with PORT=${PORT}"' >> /docker-entrypoint.sh && \
    echo 'envsubst '\''$PORT'\'' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'echo "Nginx configuration:"' >> /docker-entrypoint.sh && \
    echo 'cat /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'echo "Starting nginx..."' >> /docker-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

# Run our custom entrypoint
CMD ["/docker-entrypoint.sh"]
