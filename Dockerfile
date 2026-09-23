# ── Stage 1: Build ────────────────────────────────────────────
FROM node:20-alpine AS build

# Set corepack so we can use the configured pnpm version
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package.json, lockfile and patches
COPY package.json pnpm-lock.yaml* ./
COPY patches ./patches

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Build the frontend and the express server
RUN pnpm run build

# ── Stage 2: Runtime ──────────────────────────────────────────
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy the built files from the build stage
# Usually vite builds to /app/dist/public and esbuild outputs to /app/dist/index.js
# We need package.json for starting or if node_modules is needed.
# Since esbuild bundles the server dependencies, but packages=external means we still need node_modules
COPY --from=build /app/package.json ./
COPY --from=build /app/pnpm-lock.yaml* ./
COPY --from=build /app/dist ./dist
COPY --from=build /app/patches ./patches

# Install only production dependencies (since server packages are external)
RUN corepack enable && corepack prepare pnpm@latest --activate && \
    pnpm install --prod --frozen-lockfile

# Create a non-root user and adjust permissions
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /app

USER appuser

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "dist/index.js"]
