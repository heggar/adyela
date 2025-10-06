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

# Build the application
RUN pnpm --filter @adyela/web build

# Production stage - serve the built app
FROM nginx:alpine AS production

# Copy built files from builder
COPY --from=builder /app/apps/web/dist /usr/share/nginx/html

# Copy nginx configuration (optional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
