# ============================================================
# Stage 1: Build shared package types
# ============================================================
FROM node:20 AS shared-builder
WORKDIR /shared
COPY shared/package*.json ./
RUN npm install
COPY shared/ ./
RUN npm run build

# ============================================================
# Stage 2: Build backend application
# ============================================================
FROM node:20 AS backend-builder
WORKDIR /app

# shared must exist before npm install (backend deps include file:../shared)
COPY --from=shared-builder /shared /shared
COPY backend/package*.json ./
RUN npm install \
 && rm -rf /shared/node_modules node_modules/@app \
 && mkdir -p node_modules/@app \
 && cp -r /shared node_modules/@app/shared

# Copy backend source and build
COPY backend/ ./
RUN npm run build

# ============================================================
# Stage 3: Production runtime
# ============================================================
FROM node:20-slim AS backend-run
WORKDIR /app

ENV NODE_ENV=production

# Copy production artifacts
COPY --from=backend-builder /app/package*.json ./
COPY --from=backend-builder /app/node_modules ./node_modules
COPY --from=backend-builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/main.js"]