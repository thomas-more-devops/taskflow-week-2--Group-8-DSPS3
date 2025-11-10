# Multi-stage Dockerfile optimized for caching, small final image, and non-root runtime

# -------------------------
# Builder stage
# - uses Node 22 (Alpine)
# - copies package files first for layer caching
# - installs all dependencies (including dev) so any build steps can run here
# -------------------------
FROM node:22-alpine AS builder
WORKDIR /app

# Install build dependencies based on package lock (layer caches when package files don't change)
COPY package*.json ./
RUN npm ci --prefer-offline --no-audit --no-fund

# Copy the rest of the source code
COPY . .

# If there were build steps (e.g. bundling/minification), run them here.
# This project currently doesn't have a real build step, but keeping this target
# makes it easy to add later. Example: RUN npm run build


# -------------------------
# Production stage
# - starts from a fresh Node 22 Alpine image
# - copies only the minimal runtime artifacts
# - creates and uses an unprivileged user
# -------------------------
FROM node:22-alpine AS production
WORKDIR /app

# Create a non-root user and group
RUN addgroup -S appgroup \
	&& adduser -S appuser -G appgroup

# Set environment for production
ENV NODE_ENV=production

# Copy package files and install only production dependencies (cached independently)
COPY package*.json ./
RUN npm ci --omit=dev --prefer-offline --no-audit --no-fund

# Copy application files that are needed at runtime from builder
# Only copy the files required to run the app to keep the image small
COPY --from=builder /app/server.js ./server.js
# Copy database connection and models needed for mongoose runtime
COPY --from=builder /app/database.js ./database.js
COPY --from=builder /app/models ./models
COPY --from=builder /app/public ./public
# Ensure correct ownership and drop privileges
RUN chown -R appuser:appgroup /app
USER appuser

# Expose the app port and default command
EXPOSE 3000
CMD ["node", "server.js"]
