# ============================================================
# Stage 1: Build admin panel (Vue 2)
# ============================================================
FROM node:20 AS admin-builder
WORKDIR /app

COPY admin/package*.json ./
RUN npm install

COPY admin/ ./
RUN npm run build

# ============================================================
# Stage 2: Serve static files with nginx
# ============================================================
FROM nginx:1.27-alpine AS admin-run

# Nginx config with API and WebSocket proxy to backend
COPY admin/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=admin-builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]