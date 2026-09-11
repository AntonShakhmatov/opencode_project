# Handyman — On-Demand Home Services Marketplace

Full-stack monorepo: clients request home-service jobs, the backend auto-matches available handymen by skill and proximity (PostGIS), and handymen accept/complete jobs with real-time chat and live status updates over Socket.IO.

## Stack

| Layer      | Tech                                                                    |
|------------|-------------------------------------------------------------------------|
| Backend    | NestJS 10, TypeORM, PostgreSQL 16 + PostGIS 3.4, Socket.IO, JWT/bcrypt  |
| Mobile     | Flutter (deployed as web via nginx)                                     |
| Admin      | Vue 2.7 + Vuex + Vue Router + axios                                     |
| Shared     | `@app/shared` TypeScript types/DTOs (compiled, consumed by backend)     |
| Infra      | Docker Compose (db, backend, admin, mobile-web)                         |

## Repository Layout

```
backend/     NestJS REST + Socket.IO gateway (all API under /api)
mobile/      Flutter app (Provider state, flutter_map, socket_io_client)
admin/       Vue 2 admin dashboard
shared/      @app/shared shared TypeScript types
```

## Quick Start

### Full stack with Docker (recommended)

```bash
docker compose up --build -d
```

Wait for the backend log to show `Server running on http://localhost:3000`, then open:

- Mobile app (Flutter web): http://localhost:8081
- Admin dashboard: http://localhost:8080
- Backend API: http://localhost:3000/api
- PostGIS DB: localhost:5432 (`handyman_db`)

See `docker-compose.README.md` for service details, seed users, and common commands.

### Local development

Backend (needs a PostGIS DB; `docker compose up -d db` provides one):

```bash
cd backend
npm install
npm run start:dev
```

Mobile (Flutter ≥ 3.0; API defaults to `http://localhost:3000/api`):

```bash
cd mobile
flutter pub get
flutter run
```

Admin (proxies `/api` and `/socket.io` to `http://localhost:3000` in dev):

```bash
cd admin
npm install
npm run serve
```

## Configuration

Backend reads a `.env` file (never commit it). Supported keys (names — see `backend/src/main.ts`, `app.module.ts` for defaults):

`DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`, `DB_SYNCHRONIZE`, `JWT_SECRET`, `JWT_EXPIRATION`, `PORT`, `CORS_ORIGIN`

The Flutter web build compiles in the API base URL via `--dart-define=API_URL=/api` (same-origin through the nginx proxy).

## Verification

```bash
cd mobile && flutter analyze && flutter test   # 0 errors; 9 tests
cd backend && npm run lint && npm run build     # lint + TypeScript build
cd admin && npm run lint                        # eslint
```

## Documentation

- `PROJECT_CONTEXT.md` — project snapshot: stack, endpoints, events, entities, lifecycle, seed data
- `ARCHITECTURE.md` — deep dive: auth flow, matching, Socket.IO, mobile providers, Docker/nginx
- `TODO.md` — planned work and known issues (current, next, later)
- `DEVELOPMENT_LOG.md` — decision log
- `AGENTS.md` — OpenCode agent rules (used by this repo's `opencode.json`)

## Development

- Follow the conventions in `AGENTS.md`.
- Run the verification commands above before considering work complete.
- Changes are committed manually by the user on `master`; do not commit automatically.