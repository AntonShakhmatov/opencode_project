# Project Instructions

## Overview

Handyman is a on-demand home-services marketplace monorepo. Clients request jobs, the backend automatically matches available handymen by skill and proximity, and handymen accept/complete jobs with real-time messaging and live job-status updates. The whole stack runs in Docker on the developer machine.

This project uses OpenCode as its AI development assistant. OpenCode is configured via `opencode.json` in the project root. This file contains project rules; read `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `TODO.md`, and `DEVELOPMENT_LOG.md` for the full verified project state.

## Tech Stack

- **Backend**: NestJS 10 (TypeScript), TypeORM + **PostgreSQL with PostGIS** (`geography` Point columns, `ST_DWithin`/`ST_Distance` queries), Socket.IO, JWT (bcrypt-hashed passwords)
- **Mobile frontend**: Flutter (Dart) — deployed as Flutter **web** via nginx; mobile/platform bindings are not actively built (no Android SDK on the dev machine)
- **Admin panel**: Vue 2.7 (Vuex, Vue Router, axios)
- **Shared package**: `@app/shared` — plain TypeScript interface/DTO types used by backend and consumed by frontends
- **Infrastructure**: Docker Compose (PostGIS, backend, Vue admin nginx, Flutter-web nginx)

## Repository Layout

```
backend/     NestJS API (REST + Socket.IO gateway)
mobile/      Flutter app (lib/screens, lib/providers, lib/services, lib/models)
admin/       Vue 2 admin dashboard
shared/      @app/shared shared TypeScript types
```

## Conventions

- Follow existing code style and naming conventions when making changes.
- Do not modify files inside the `.opencode/` directory (Python virtual environment).
- Keep changes focused and minimal.
- Prefer editing existing files over creating new ones unless necessary.
- Never commit, push, amend, or rebase unless explicitly asked. The repo lives on the `master` branch and the user commits manually.
- Never change git config, hooks, or force operations unless explicitly asked.

### NestJS Backend
- Use dependency injection and modular architecture (`Controller` + `Service` + `Module` per feature; entities registered in the module's `TypeOrmModule.forFeature`).
- **Database access uses TypeORM — not Prisma.** All entities live under `backend/src/modules/<feature>/*.entity.ts` and are autocreated via `synchronize`, so a schema change is a code change (no migrations).
- Controllers return plain objects; validation is global (`ValidationPipe` with `whitelist` + `transform`).
- All routes are under the global prefix `/api`. Auth is enforced by global `JwtAuthGuard` + `RolesGuard`; mark endpoints `@Public()` if they must be reachable without a token. Do not bypass the global guard.
- Route ownership rules: only `cancelJob` and `acceptJob` check ownership/state today; do not assume other job routes are scoped to the caller (see `TODO.md`).

### Flutter (mobile)
- Follow the Dart style guide and Flutter best practices.
- State management is **Provider** (not Bloc/Riverpod). Add providers in `mobile/lib/providers/`, register them in `main.dart`'s `MultiProvider`.
- HTTP is a thin static helper `ApiService` (15s timeout); JSON parsing lives in the model `fromJson` factories.
- `Intl` (DateFormat) is used for date formatting in chat/reviews screens; UI helpers for job status color/label live in `mobile/lib/app_constants.dart` — reuse `jobStatusColor()`/`jobStatusLabel()` instead of duplicating switches.
- Network failures surface through provider `_error` fields; success/error SnackBars are shown from screens.

### Socket.IO / real-time rules (important)
- Real-time features run on **Socket.IO only — no HTTP polling**. Do not replace living socket flows with polling, and do not break existing listeners.
- The client authenticates by sending the JWT in the handshake (`socket.connect(token)` sets `auth.token`); the gateway verifies it and rejects refresh tokens.
- A client must send `register {userId}` after connecting so the server can route user-targeted events (`jobOffered`), and `joinJob {jobId, userId}` (room `job:<jobId>`) before job-targeted events can arrive.
- Joining/leaving the job room and registering/removing handlers is the screen's job: `SocketService.joinJob`, `SocketService.leaveJob`, `SocketService.on(event, handler)`, and `SocketService.off(event, handler)` (pass the exact handler reference to remove only it — not `off(event)` alone, which would drop other listeners).
- Inspect the existing gateway (`backend/src/modules/chat/chat.gateway.ts`) and matching service (emits `matchingStarted`, `handymanFound`, `matchingFailed`, `jobOffered`) before touching anything realtime; event names and payload shapes are load-bearing.
- Known gap: REST `PUT /jobs/:id` and `PUT /jobs/:id/accept` persist status changes but the backend **does not emit** socket events from the REST path (`jobStatusUpdated` is only emitted by the gateway's `updateJobStatus` handler; `jobAccepted` is never emitted). Do not "fix" this by inventing new events that clients do not listen for; check listeners first.

### Vue 2 admin
- Follow the Vue 2 style guide; state management is Vuex (single store in `admin/src/store/index.js`).
- The admin axios client is defined in the store (base URL `/api`, Bearer token interceptor, 401 -> redirect to `/login`).
- Admin-only routes are enforced in the router (`meta.requiresAuth`) and, on login, by rejecting non-`admin` roles.

### Docker
- Full stack runs via `docker compose up --build -d`. Services: `db` (:5432, postgis/postgis:16-3.4), `backend` (:3000), `admin` (:8080), `mobile-web` (:8081). See `docker-compose.README.md`.
- Container runtime does NOT include the Flutter toolchain; Flutter web is built inside the `mobile/Dockerfile.web` builder stage. Do not run `flutter` commands against the running container.
- Backend syncs the schema on startup (`DB_SYNCHRONIZE=true`). Wipe the database volume (`docker compose down -v`) to reset seed data.
- Do not edit `.dockerignore` or `.gitignore` unless there is a real reason; they exclude `.env`, `node_modules`, build outputs, and scratch scripts.

## Verification

- Mobile: `flutter analyze` (expect 0 errors, infos ok) and `flutter test` (currently 9 tests) from `mobile/`. Run these before considering Flutter work complete.
- Backend: `npm run lint` and `npm run build` from `backend/`. Note: jest is configured but there are **no test files** yet.
- Admin: `npm run lint` from `admin/`.
- After significant API/realtime changes, verify end-to-end against the running Docker stack (interfaces: http://localhost:8081 for the app, http://localhost:8080 for admin; API at http://localhost:3000/api).

## Known Limitations and Characteristics

- No CI/CD pipeline is configured (no `.github/`).
- Live push coverage is partial: status changes made via REST don't reach other clients in real time (see Socket.IO rules above).
- `GET /jobs` and `GET /jobs/:id` currently return any job to any authenticated user (no role/ownership filtering).
- Backend has no automated tests; mobile has widget/unit tests only.
- `GET /users`, `PUT /users/:id`, `DELETE /users/:id` are unauthenticated-role admin-style endpoints reused by the app (profile load/update) and admin panel.
- Job matching is auto-started with graduated radius expansion on every job creation; do not add manual handyman-assignment endpoints without considering the matcher.