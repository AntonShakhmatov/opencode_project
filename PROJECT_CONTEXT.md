# Project Context

Verified snapshot of the Handyman project as of 2026-09-11. Everything here is grounded in the current source code; see `DEVELOPMENT_LOG.md` for how it got here and `ARCHITECTURE.md` for the deep dive.

## What This Is

On-demand home-services marketplace (monorepo):

1. A **client** posts a job with a location and service type.
2. The **backend** auto-matches an available handyman whose skills cover the job, searching with an expanding radius.
3. The **handyman** gets a live offer, accepts, then drives the job status forward while the client follows in real time (chat + status updates over Socket.IO).
4. On completion the client can **rate** the handyman, which updates their aggregate rating.

Users are `client`, `handyman`, or `admin`. The Vue admin panel shows dashboard stats, users, jobs, and reviews.

## Tech Stack

- **Backend**: NestJS 10, TypeORM 0.3, PostgreSQL 16 + PostGIS 3.4, Socket.IO 4.7, JWT (`@nestjs/jwt`), bcrypt, class-validator. Global `ValidationPipe` (`whitelist` + `transform`).
- **Mobile**: Flutter (SDK `>=3.0.0 <4.0.0`), Provider, shared_preferences, `flutter_map` + `latlong2`, `socket_io_client`, `http`. Deployed as web (nginx) — no Android/iOS toolchain on the dev machine.
- **Admin**: Vue 2.7, Vuex 3, Vue Router 3, axios.
- **Shared**: `@app/shared` (`file:../shared` dependency) — hand-written TypeScript interfaces (users, jobs, reviews, messages, geo types, DTOs) compiled by the backend and mirrored by Flutter models.
- **Infra**: Docker Compose. No CI/CD (no `.github/`).

## Repository Layout

```
backend/     NestJS API (REST + Socket.IO gateway)
mobile/      Flutter app (lib/screens, lib/providers, lib/services, lib/models)
admin/       Vue 2 admin dashboard
shared/      @app/shared shared TypeScript types
```

## Authentication

- `POST /api/auth/register` and `POST /api/auth/login` (both `@Public()`) return `{ accessToken, refreshToken, user: { id, email, name, role } }`.
- Access token: JWT `{ sub, email, role }`, expires 1d. Refresh token: same + `type: 'refresh'`, expires 7d. Passwords bcrypt-hashed (10 rounds).
- Global `JwtAuthGuard` protects every route except `@Public()`-marked ones; it rejects refresh tokens for API access. Global `RolesGuard` enforces `@Roles('admin')` (used on the admin controller).
- Flutter stores `auth_token` / `auth_user` in SharedPreferences (`AuthProvider.restore`).
- Socket.IO authenticates via `handshake.auth.token` (see `ARCHITECTURE.md`).

## Data Model

Entities under `backend/src/modules/<feature>/*.entity.ts`. Schema is created by TypeORM `synchronize` — **a schema change is a code change; there are no migrations**.

### User (`users`)

`id` (uuid) · `email` (unique) · `name` · `phone?` · `password` (`select: false`, bcrypt) · `role` enum (`client|handyman|admin`) · `avatar?` · `rating` decimal(3,2)? · `reviewCount` (default 0) · `skills` simple-array · `location` geography Point (SRID 4326, spatial index)? · `isAvailable` (default false)

### Job (`jobs`)

`id` (uuid) · `clientId` + `client` relation · `handymanId?` + `handyman` relation · `serviceType` · `description` (text) · `status` enum · `location` geography Point (SRID 4326, spatial index) · `address?` · `estimatedPrice?`/`finalPrice?` decimal(10,2) · `scheduledAt?`/`startedAt?`/`completedAt?` · `createdAt`/`updatedAt`

Statuses: `pending` (enum default, unused by create) · `searching` (newly created) · `matched` · `accepted` · `en_route` · `in_progress` · `completed` · `cancelled`

### Review (`reviews`)

`id` (uuid) · `jobId` + `job` relation · `reviewerId` + `reviewer` relation · `revieweeId` + `reviewee` relation · `rating` (int) · `comment?` (text) · `createdAt`. Creating a review recomputes the reviewee's `rating` (AVG) and `reviewCount` (COUNT) and writes them back to the user row.

### Message (`messages`)

`id` (uuid) · `jobId` + `job` relation · `senderId` + `sender` relation · `content` (text) · `createdAt`

## REST API

Global prefix `/api`. All endpoints require a Bearer token unless marked `@Public` or admin-only. `AuthResponse` shapes and DTOs live in `shared/src/api.ts`.

| Method | Path                               | Notes                                                        |
|--------|------------------------------------|--------------------------------------------------------------|
| GET    | `/api`                             | `@Public` hello                                              |
| POST   | `/api/auth/login`                  | `@Public` → tokens                                          |
| POST   | `/api/auth/register`               | `@Public` → tokens                                          |
| POST   | `/api/auth/refresh`                | `@Public`, validates `type: 'refresh'`                      |
| GET    | `/api/auth/me`                     | profile shape (id/email/name/phone/role/avatar/rating/skills/isAvailable) |
| POST   | `/api/users`                       | create user (used by seed)                                  |
| GET    | `/api/users`                       | list all users (admin + app list)                           |
| GET    | `/api/users/:id`                   | single user (used by app profile load)                      |
| PUT    | `/api/users/:id`                   | update (used by app profile edit)                           |
| DELETE | `/api/users/:id`                   | remove                                                       |
| POST   | `/api/jobs`                        | create (set `clientId = req.user.id`), status `searching`, starts matching |
| GET    | `/api/jobs`                        | all jobs (+ client/handyman relations), newest first         |
| GET    | `/api/jobs/:id`                    | single job (+ relations)                                     |
| GET    | `/api/jobs/client/:clientId`       | jobs for a client (+ handyman relation)                      |
| GET    | `/api/jobs/handyman/:handymanId`   | jobs for a handyman (+ client relation)                      |
| PUT    | `/api/jobs/:id`                    | update; sets `startedAt` on `in_progress`, `completedAt` on `completed`; rejects completed/cancelled; stops matching on completed/cancelled |
| PUT    | `/api/jobs/:id/accept`             | only from `searching`/`matched`; sets `handymanId = req.user.id`, status `accepted`, stops matching |
| PUT    | `/api/jobs/:id/cancel`             | owner-only (`clientId` or `handymanId`), rejects completed   |
| POST   | `/api/reviews`                     | create (sets `reviewerId = req.user.id`), refresh reviewee rating/count |
| GET    | `/api/reviews`                     | all reviews (+ reviewer/reviewee)                            |
| GET    | `/api/reviews/job/:jobId`          | reviews for a job                                            |
| GET    | `/api/reviews/user/:userId`        | reviews where the user is the reviewee (used by "View My Ratings") |
| POST   | `/api/messages`                    | create (sets `senderId = req.user.id`)                       |
| GET    | `/api/messages/job/:jobId`         | messages for a job, oldest first (+ sender)                  |
| PUT    | `/api/location/:userId`            | update user location (`GeoLocation`, writes via `ST_GeomFromGeoJSON`) |
| GET    | `/api/location/nearby`             | `lat`, `lng`, `radius`, optional `serviceType` → available handymen w/ distance (`ST_DWithin`, ordered by distance) |
| GET    | `/api/location/:userId`            | get a user's location                                        |
| GET    | `/api/admin/stats`                 | `@Roles('admin')` dashboard stats                            |
| GET    | `/api/admin/jobs/recent?limit=`    | `@Roles('admin')` recent jobs (+ relations)                  |

Note: job list/detail endpoints currently return any job to any authenticated user — no ownership/role filtering exists (see `TODO.md` and `AGENTS.md`'s known limitations).

## Socket.IO Events

Gateway: `backend/src/modules/chat/chat.gateway.ts`. Client handshake auth: `{ token }`. Namespaces/rooms: `job:<jobId>`.

### Client → server

| Event            | Payload                                    | Effect                                    |
|------------------|--------------------------------------------|-------------------------------------------|
| `register`       | `{ userId }`                               | map userId → socket (for user-targeted pushes); ack `registered` |
| `joinJob`        | `{ jobId, userId }`                        | join room `job:<jobId>`; ack `joinedJob`  |
| `leaveJob`       | `{ jobId }`                                | leave room; ack `leftJob`                 |
| `sendMessage`    | `{ jobId, senderId, content }`             | persist message; emit `newMessage` to room |
| `updateLocation` | `{ userId, location }`                     | persist location; broadcast `locationUpdated` to all sockets |
| `updateJobStatus`| `{ jobId, status, userId }`                | persist via `JobsService.update`; emit `jobStatusUpdated` to room |
| `handymanFound`  | `{ jobId, handymanId }`                    | re-emit `handymanFound` to room (defensive copy) |

### Server → client

| Event            | Payload                                                                | Target      | Emitter              |
|------------------|------------------------------------------------------------------------|-------------|----------------------|
| `matchingStarted`| `{ jobId }`                                                            | job room    | matching service     |
| `matchingFailed` | `{ jobId, message }`                                                   | job room    | matching service     |
| `handymanFound`  | `{ jobId, handymen: [...] }` (matches use this shape — `handymen` array) | job room  | matching service     |
| `jobOffered`     | `{ jobId, serviceType, description, address, offeredJobId }`           | matched handyman's socket | matching service |
| `newMessage`     | `{ id, jobId, senderId, content, createdAt }`                          | job room    | gateway `sendMessage` |
| `jobStatusUpdated`| `{ jobId, status, updatedAt }`                                        | job room    | gateway `updateJobStatus` |
| `locationUpdated`| `{ userId, location }`                                                 | all sockets | gateway `updateLocation` |

Client listeners today: `home_screen.dart` registers `handymanFound`, `jobOffered`, `jobAccepted`, `jobStatusUpdated`; `job_detail_screen.dart` registers `jobStatusUpdated`, `jobAccepted`, `handymanFound` (per-job with saved handler refs, removed on dispose); `chat_provider.dart` registers `newMessage`.

Known inconsistency: the gateway `jobStatusUpdated` fires only from the socket `updateJobStatus` path, and REST `PUT /jobs/:id` / `PUT /jobs/:id/accept` never emit socket events. The REST routes are what the Flutter app actually calls for accept/status changes (`JobProvider.acceptJob` / `updateJobStatus`), so cross-client live status push does not work end-to-end today. `jobAccepted` is never emitted by the server (0 references), and the matching service's `handymanFound` sends `{ jobId, handymen: [...] }` while the detail screen reads `data['handymanId']`/`data['handymanName']` (payload mismatch). See `TODO.md`.

## Job Lifecycle

```
create (searching) ──auto-match──> matched ──handyman accept──> accepted
accepted ──> en_route ("Start Heading There") ──> in_progress ("Start Work", startedAt set)
in_progress ──> completed (completedAt set)          cancel (owner, any non-completed state) ──> cancelled
```

- Matching (`job-matching.service.ts`): radius steps 1000 m (0s) → 3000 m (20s) → 5000 m (20s) → 10000 m (30s) → 20000 m (30s) → 50000 m (60s). Each step queries available handymen with matching skill via PostGIS, takes the nearest as a match (`status='matched'`, `handymanId` set), emits `handymanFound` to the job room after `MATCH_NOTIFY_DELAY_MS` (default 2500) and `jobOffered` to that handyman; exhausted steps emit `matchingFailed`. Matching is stopped on accept/cancel/completion.
- Accept is restricted to jobs in `searching`/`matched`. Cancel rejects completed jobs and requires ownership.
- Mobile UI (`app_constants.dart`): `matched` → "New Offer", `accepted` → "Accepted", `en_route` → "On the Way", `in_progress` → "In Progress", `completed` → "Completed", `cancelled` → "Cancelled". The job detail stepper renders Matched → Accepted → On the Way → In Progress → Done.

## Flutter App

- `main.dart`: restores `AuthProvider`, then `MultiProvider` (auth, job, socket, review, `ProxyProvider`-built chat). Named routes `/`, `/login`, `/register`, `/home`.
- Providers: `AuthProvider` (login/register/restore/profile/update/logout), `JobProvider` (fetch client/handyman/all jobs, create job, nearby search, accept, status update, `fetchJobById`, socket-sourced `addJobFromSocket`/`updateJobFromSocket`; buckets jobs into available/matched, active/accepted+en_route+in_progress+searching, completed/completed+cancelled), `ChatProvider` (load messages, listen for `newMessage` by jobId, send), `ReviewProvider` (create review, fetch by reviewee, rated job ids persisted in SharedPreferences `reviewed_job_ids`).
- Services: `ApiService` (static helpers, 15s timeout, unwraps list responses into `{ data: [...] }`), `SocketService` (connect with auth token, `registerUser`, `joinJob`/`leaveJob`, `on`/`off(event, handler)`, `sendMessage`).
- Screens: login, register, home (client map + nearby list, handyman dashboard, socket snackbars), create job, job list, handyman jobs (Available/Active/Done tabs), job detail (status chip, stepper, map, actions, chat/rate links), chat, profile, edit profile, rate job, reviews.
- Web index (`mobile/web/index.html`): default title `app_mobile`/default favicon (unchanged scaffold).
- Map tiles come from OpenStreetMap; demo center defaults to `DemoLocation` (40.7128, -74.0060), overridable with `MAP_LAT`/`MAP_LNG` dart-defines.

## Admin Panel

- Routes: `/login` (LoginView), `/` HomeView, `/users`, `/jobs`, `/reviews` (all `meta.requiresAuth`).
- Store: token/user in localStorage (`handyman_admin_token`/`_user`), axios instance baseURL `/api`, request interceptor adds Bearer, response interceptor redirects to `/login` on 401. Login rejects non-admin roles.
- Views: dashboard stats (`/admin/stats`), users/jobs lists (edit via `PUT /users/:id` / `PUT /jobs/:id`), reviews list.
- Todo comment in code: `UsersView.vue` edit-modal is unimplemented.

## Docker

`docker-compose.yml` services (see `docker-compose.README.md` for usage/seed):

| Service   | Image/build                 | Port        | Notes                                  |
|-----------|-----------------------------|-------------|----------------------------------------|
| db        | `postgis/postgis:16-3.4`    | 5432:5432   | volume `postgres-data`, pg_isready healthcheck |
| backend   | `backend/Dockerfile`        | 3000:3000   | depends on db healthy; env `DB_*`, `PORT` |
| admin     | `admin/Dockerfile`          | 8080:80     | nginx proxies `/api/`, `/socket.io/`, SPA fallback |
| mobile-web| `mobile/Dockerfile.web`     | 8081:80     | nginx proxies API + sockets, no-cache for Flutter entrypoints |

- Backend Dockerfile: 3 stages (build `shared`, install + build backend, slim runtime running `node dist/main.js`).
- Admin/mobile images: builder stages (`node:20` / `ghcr.io/cirruslabs/flutter:stable` with `flutter build web --release --dart-define=API_URL=/api`) → `nginx:1.27-alpine`.
- nginx proxies: `/api/` → `backend:3000/api/`, `/socket.io/` → `backend:3000` (upgrade headers). Flutter entrypoints (`index.html`, `main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `version.json`) are served `no-cache`; static assets get 7-day caching.

## Environment Variables

Read from `backend/.env` (not committed; `.env` gitignored). Keys referenced by code/config: `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`, `DB_SYNCHRONIZE`, `JWT_SECRET`, `JWT_EXPIRATION`, `PORT`, `CORS_ORIGIN`, plus socket-matching tunable `MATCH_NOTIFY_DELAY_MS` (default 2500). Docker Compose sets the `DB_*` and `PORT` values for the backend container; `DB_SYNCHRONIZE=true` there.

## Seed Data

`UsersModule.onModuleInit` seeds **only when the users table is empty**: `admin@handyman.com` (Admin User), `client@test.com` (Test Client), `client2@test.com` (Jane Client), and four handymen — `plumber@test.com` (Mike Plumber, skills plumbing/general_repair), `electrician@test.com` (John Electrician, electrical/appliance_repair), `carpenter@test.com` (Tom Carpenter, carpentry/painting), `cleaner@test.com` (Sarah Cleaner, cleaning/landscaping). Handymen are seeded `isAvailable: true` with points near the demo center (40.71x, -74.00x). Wipe with `docker compose down -v` to re-seed. Credentials are documented in `docker-compose.README.md`.

## Testing State

- Mobile: `flutter test` — 9 tests across `test/smoke_test.dart`, `widget_test.dart`, `user_model_test.dart`, `reviews_test.dart`. `flutter analyze`: 0 errors (infos only).
- Backend: jest configured in `package.json` but no `*.spec.ts` files exist.
- Admin: no test setup (eslint only).

## Known Issues / Gaps

- Real-time status push from REST actions is missing (backend emits only from the socket path); `jobAccepted` never emitted; `handymanFound` payload shape mismatch.
- `GET /jobs` / `GET /jobs/:id` not role/ownership-scoped.
- `/users` endpoints (list/get/update/delete) are generic and unprotected by role.
- Client sees label "New Offer" for `matched` status (deduped shared helper; previously "Matched").
- `create_job_screen.dart` has a `// TODO: Get actual location` (demo location used).
- `go_router` is declared in `mobile/pubspec.yaml` but unused (named routes + `Navigator.push` are used instead).

See `TODO.md` for the full backlog.