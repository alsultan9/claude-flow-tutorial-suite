# Multi-stage Node.js Application Dockerfile
# Optimized for production with security best practices

# ============================================================================
# Builder Stage - Build the application
# ============================================================================
FROM node:18-alpine AS builder

# Security: Create app directory and set permissions
WORKDIR /app

# Security: Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy package files and install dependencies
COPY package*.json ./
COPY tsconfig*.json ./

# Install all dependencies (including dev dependencies for building)
RUN npm ci --include=dev

# Copy source code
COPY src/ ./src/
COPY tests/ ./tests/

# Build the application
RUN npm run build

# Remove dev dependencies to reduce size
RUN npm ci --only=production && npm cache clean --force

# ============================================================================
# Production Stage - Create final lightweight image
# ============================================================================
FROM node:18-alpine AS production

# Security: Install dumb-init and curl for health checks
RUN apk add --no-cache dumb-init curl

# Security: Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Security: Copy files with proper ownership
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/package.json ./package.json

# Create logs and temp directories with proper permissions
RUN mkdir -p /app/logs /app/temp && \
    chown -R appuser:nodejs /app/logs /app/temp

# Security: Switch to non-root user
USER appuser

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/api/v1/health || exit 1

# Expose port (configurable via environment)
EXPOSE ${PORT:-3000}

# Environment defaults
ENV NODE_ENV=production
ENV PORT=3000

# Start application with dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]