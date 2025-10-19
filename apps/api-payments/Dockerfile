# Multi-stage build for API Payments microservice (Node.js)

# Stage 1: Dependencies
FROM node:20-alpine as dependencies

WORKDIR /app

# Copy dependency files
COPY package.json ./

# Install dependencies
RUN npm install --only=production

# Stage 2: Builder
FROM node:20-alpine as builder

WORKDIR /app

# Copy dependency files
COPY package.json ./

# Install all dependencies (including dev)
RUN npm install

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Stage 3: Runtime
FROM node:20-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001

# Copy production dependencies
COPY --from=dependencies /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# Set ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run application
CMD ["node", "dist/index.js"]
