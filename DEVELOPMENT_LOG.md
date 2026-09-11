# Development Log

Important decisions and the reasoning behind them, recorded as of 2026-09-11. Commit-shortlex-based entries; reverse-chronological (newest first). Where a commit is named, the work is verified in it.

## Monorepo & Stack

- **Monorepo with a shared package**: `backend` (NestJS), `mobile` (Flutter), `admin` (Vue 2), `shared` (`@app/shared`, `file:../shared`). Rationale: the API surface (users/jobs/reviews/messages/geo types, DTOs) is shared knowledge between backend and frontends; keeping shared TS types in one package avoids drift. Frontends mirror the shapes with hand-written models (Flutter `fromJson`).
- **TypeORM + PostGIS, schema from code**: entities under `backend/src/modules/<feature>/*.entity.ts`, auto-`synchronize` on boot, `geography(Point, 4326)` columns with spatial indexes, `ST_DWithin`/`ST_Distance`/`ST_GeomFromGeoJSON`/`ST_AsGeoJSON` via query builder. Chosen over migrations for a small evolving project; consequence: DB volume wipe (`docker compose down -v`) resets schema + seed.
- **Full Docker Compose as the canonical run path** (`docker-compose.yml` + `docker-compose.README.md`): PostGIS 16-3.4, backend on :3000, Vue admin nginx on :8080, Flutter-web nginx on :8081, health-gated `depends_on`, persistent volume.

## Scale & Verification

- **`d0f072c first commit`** — initial scaffold across all four packages.
- **`902729e first stage devel. commit`** — first working milestone: auth, users, basic jobs, matching, location, chat gateway, admin panel, seed data.
- **`5deb8b8 fix profile rating parsing, CORS, web cache headers + add reviews UI commit`** — three fixes + reviews feature:
  - Profile/rating parsing: Postgres decimal columns (`decimal(3,2)`, `decimal(10,2)`) serialize as strings; the mobile `User.fromJson`/`Handyman.fromJson` were returning `double`/null for ratings, breaking profile render and nearby-list ratings. Fixed by tolerant numeric parsing (`double.tryParse(value.toString())`) in `User.fromJson`, `Handyman.fromJson`.
  - CORS: Flutter test browsers and dev ports need the backend to allow cross-origin; `main.ts` now sets `app.enableCors({ origin: true, credentials: true })`.
  - Web cache headers: Flutter web redeploys were masked by cached `main.dart.js`/`flutter_bootstrap.js`/`flutter_service_worker.js`/`version.json`/`index.html`; mobile-web nginx now emits `no-cache` for those entrypoints (static assets remain 7-day cached) so a fresh `docker compose up --build -d` shows new JS immediately.
  - Reviews UI: `mobile/lib/providers/review_provider.dart` (persists rated job ids in SharedPreferences `reviewed_job_ids`), `RateJobScreen`, `ReviewsScreen`, "Rate Handyman"/"View My Ratings" entries in the job detail and handyman dashboard. Backend `ReviewsService.create` recomputes the reviewee's `rating` (AVG) + `reviewCount` (COUNT) after each review.
- **`23864ec job detail screen with live status timeline, map, and actions commit`** — the current head:
  - New `job_detail_screen.dart` (~630 lines): live status chip, step timeline (Matched→Accepted→On the Way→In Progress→Done), cancelled banner, description card, flutter_map preview, address, prices/timestamps, handyman name, role-aware actions (handyman: Decline/Accept → Start Heading There → Start Work → Chat/Complete; client: Chat, Rate Handyman, waiting spinner for searching/matched).
  - `app_constants.dart`: shared `jobStatusColor()` / `jobStatusLabel()` helpers; refactored list screens to reuse them (removes per-screen switch duplications).
  - Job cards in `job_list_screen.dart` and `handyman_jobs_screen.dart` now open the detail screen via InkWell.
  - `home_screen.dart`: the `jobOffered` snackbar "View" action fetches the job by id and opens `JobDetailScreen` (falls back to `HandymanJobsScreen`).
  - `JobProvider.fetchJobById()` added; `updateJobFromSocket()` now preserves `handymanName`.
  - `SocketService.off(event, handler)` added so a screen can remove only its own listener (the detail screen saves handler refs and unremoves exactly them on `dispose`, alongside `leaveJob`).
  - Verified: `flutter analyze` 0 errors (20 infos), `flutter test` 9/9, mobile-web rebuilt/redeployed (`docker compose up --build -d`), and `GET /api/jobs/:id` returns nested `handyman.name` (manual check against seed handyman Mike Plumber).

## Architecture Decisions (with context)

- **JWT with global guard, not per-route auth**: `JwtAuthGuard` + `RolesGuard` registered as `APP_GUARD` in `app.module.ts`; `@Public()` opt-out. Keeps every new endpoint protected by default; unintended public endpoints are explicit exceptions (only auth routes + root hello today).
- **Two-token JWT, refresh tokens not usable for API/socket access**: access 1d, refresh 7d with `type:'refresh'`; both `JwtAuthGuard` and the socket middleware reject that type. The Flutter app currently stores only the access token.
- **Socket.IO rooms keyed `job:<jobId>` + a userId→socket map**: room-scoped events (`newMessage`, matching events, `jobStatusUpdated`) go to everyone on the job; user-targeted async pushes (`jobOffered`) use the `register` map. Chosen over letting clients filter events by id.
- **Auto-matching with graduated radius expansion**: per-job timer chain (1km→50km, delays 0s→60s, deadlines capped at ~170s worst case), nearest-available-with-skill wins, `MATCH_NOTIFY_DELAY_MS` (2500) before `handymanFound`. Rationale: find someone nearby first but keep escalating instead of scoping to one radius. Trade-off: late arrivals in a step aren't considered; matching is stopped on accept/cancel/completion.
- **One `JobProvider` job list as single source of truth**: fetches land in `_jobs`, `updateJobFromSocket`/`addJobFromSocket` mutate it, `_categorizeJobs` buckets into available/active/completed; screens read buckets. Keeps all client views consistent as statuses arrive from REST or (when it works) sockets.
- **REST-first for user-initiated job actions** (accept/status via `PUT`), sockets reserved for push/chat/locations. Documented limitation: the two paths don't yet reconcile — REST mutations emit nothing, only the gateway's `updateJobStatus` emits `jobStatusUpdated`, and `jobAccepted` is never emitted. See `TODO.md` items 1–3. The full realtime wiring exists (gateway handlers, rooms, client listeners) but the emission side is incomplete.

## Known Trade-offs Accepted

- Web-only Flutter deployment; no Android/iOS builds on the dev machine.
- Backend schema changes are code changes (`synchronize`), no migration history.
- No CI/CD yet.
- `GET /jobs`/`GET /jobs/:id` return any job to any authenticated user (not role-scoped yet — accepted for this stage; see TODO).
- Seed data only exists if the users table is empty at boot.
- Mobile job create uses demo coordinates (`create_job_screen.dart` TODO) — no GPS device on the dev setup.