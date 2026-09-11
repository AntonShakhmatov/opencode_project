# Architecture

Deep-dive into how the Handyman system actually works, mapped to code. Companion to `PROJECT_CONTEXT.md` (snapshot) and `AGENTS.md` (agent rules). Verified as of 2026-09-11.

## High-Level Diagram

```
                       ┌───────────────────────────┐
  client (Flutter web) │  nginx (mobile-web :8081) │──/api/──> backend :3000 ──> postgis :5432
                       │  └ proxies /socket.io/    │──ws─────> backend :3000 (Socket.IO)
                       └───────────────────────────┘
                       ┌───────────────────────────┐
  admin (Vue web)      │  nginx (admin :8080)      │──/api/──> backend :3000
                       │  └ proxies /socket.io/    │
                       └───────────────────────────┘
```

- During local dev the Flutter app targets `API_URL` (default `http://localhost:3000/api`); the web/`Dockerfile.web` build uses `--dart-define=API_URL=/api` so the browser talks same-origin to nginx, which proxies to the backend.
- Socket.IO connects to the API origin minus the `/api` suffix (`SocketService._socketUrl`): `http://localhost:3000` in dev, same origin through nginx in Docker.

## Backend Structure (NestJS)

`backend/src/main.ts` — global prefix `api`, global `ValidationPipe` (`whitelist`+`transform`), CORS `origin: true`, listens on `PORT || 3000`.

`app.module.ts` — `ConfigModule.forRoot({ isGlobal })` reading `.env`; `TypeOrmModule.forRootAsync` (postgres, `synchronize` default true); registers feature modules `Users, Jobs, Reviews, Messages, Location, Chat, Admin, Auth`; registers global guards via `APP_GUARD` = `JwtAuthGuard` then `RolesGuard`.

Auth flow (REST):
1. `POST /api/auth/register|login` (`@Public`) → `AuthService` → `AuthResponse { accessToken, refreshToken, user }`. Access = `{sub,email,role}` 1d; refresh = same + `type:'refresh'` 7d (secret from `JWT_SECRET`).
2. Later requests send `Authorization: Bearer <accessToken>`.
3. `JwtAuthGuard` verifies it (rejects `type:'refresh'`), sets `request.user = {id, email, role}`.
4. `RolesGuard` checks `@Roles(...)` metadata (only admin controller uses it).

Database access is exclusively TypeORM repositories/query-builder. `synchronize` auto-creates schema from `*.entity.ts`; PostGIS is used through raw SQL helpers inside query builder: `ST_GeomFromGeoJSON` (writes), `ST_AsGeoJSON`, `ST_Distance`, `ST_DWithin`, `ST_MakePoint`, `ST_SetSRID` (reads/nearby). Points are stored as `geography(Point, 4326)` with longitude-first coordinates (`[lng, lat]`).

## Job Flow End-to-End

**Create** (`POST /api/jobs`): `JobsService.create(clientId, dto)` builds `location = {type:'Point', coordinates:[lng, lat]}`, sets `status='searching'`, saves, then `JobMatchingService.startMatching(job)`.

**Matching** (`job-matching.service.ts`), per job, on a timer chain:
- Emits `matchingStarted {jobId}` to `job:<jobId>`.
- Steps `[{1000,0},{3000,20000},{5000,20000},{10000,30000},{20000,30000},{50000,60000}]` (radius m, delay ms).
- Each step: reload job; bail unless still `searching`; `LocationService.findNearbyHandymen(location, radius, serviceType)` → available (`role=handyman`, `isAvailable=true`) users within radius having the skill, ordered by distance.
- On a hit: `JobsService.update(jobId, {status:'matched', handymanId})`, then after `MATCH_NOTIFY_DELAY_MS` (2500) emit `handymanFound {jobId, handymen:[...]}` to the job room, and immediately `ChatGateway.emitToUser(handyman.userId, 'jobOffered', {jobId, serviceType, description, address, offeredJobId})`.
- If a step finds nobody → schedule next step; if all steps exhausted → `matchingFailed`.

**Client-side reception**: the matched handyman's home screen shows a "New job offer!" snackbar (from `jobOffered`) whose "View" action calls `JobProvider.fetchJobById` and opens `JobDetailScreen` (falls back to `HandymanJobsScreen`). The client's detail/list screens listen for room events (`handymanFound`, `jobStatusUpdated`, `jobAccepted`) but — see the real-time gap below — the server currently never emits `jobAccepted`, and the REST-driven status updates emit nothing, so in practice both parties rely on their own REST calls plus `newMessage`/`jobOffered` pushes.

**Accept** (`PUT /api/jobs/:id/accept` with the handyman's token): `acceptJob` requires status `searching`|`matched`, sets `handymanId = req.user.id`, `status='accepted'`, stops matching.

**Status progression** (`PUT /api/jobs/:id`): guarded against completed/cancelled; sets `startedAt` on `in_progress`, `completedAt` on `completed`, stops matching on completed/cancelled. The Flutter detail screen drives this with "Start Heading There" (`en_route`), "Start Work" (`in_progress`), "Complete" (`completed`); Decline maps to `cancelled`.

## Real-Time (Socket.IO) Architecture

Gateway: `webSocketGateway` in `chat.gateway.ts`.

### Connect & authenticate
- `SocketService.connect(token)` (Flutter) opens a websocket with `auth: { token }` (`socket_io_client`, reconnection on, 10 attempts, 2s delay).
- `afterInit` installs a middleware: verifies the JWT from `handshake.auth.token`; rejects missing, invalid, or `type:'refresh'` tokens; stores `socket.data.userId` and `socket.data.role`.

### Addressing
- `register {userId}` → `userSockets: Map<userId, socketId>` (one socket per user; re-register overwrites). Used by `emitToUser` for `jobOffered`.
- `joinJob {jobId, userId}` → `client.join('job:'+jobId)`; `jobSockets: Map<jobId, Set<socketId>>` bookkeeping; `leaveJob` mirrors it. Used by `emitToJob` and `server.to(room)` for room-scoped events.
- `handleDisconnect` cleans both maps.
- Room-scoped events emitted from services in other modules reach the gateway via injected `ChatGateway` (matching service calls `emitToJob`/`emitToUser`).

### Message send path
Client `ChatProvider.sendMessage` → socket `sendMessage {jobId, senderId, content}` → gateway persists via `MessagesService.create` and emits `newMessage {id, jobId, senderId, content, createdAt}` to the job room. `ChatProvider.listenForMessages(jobId)` adds any `newMessage` whose `jobId` matches (deduped by id).

### Live update path (as shipped)
Gateway `updateJobStatus {jobId, status, userId}` → `JobsService.update` → emit `jobStatusUpdated {jobId, status, updatedAt}` to room. This handler exists and works, **but the Flutter app never calls it** (it uses REST `PUT /jobs/:id`; `JobProvider.updateJobStatus`). Correspondingly, REST updates emit nothing. Net effect: `jobStatusUpdated`/`jobAccepted` listeners in `job_detail_screen.dart`/`home_screen.dart` fire only if some client emits those gateway events manually, which none do today. This is the single biggest real-time gap — see `TODO.md`.

## Flutter Architecture

- **State**: `MultiProvider` in `main.dart` — `AuthProvider`, `JobProvider`, `SocketService` (ChangeNotifier), `ReviewProvider`, `ChatProvider` (built from `SocketService` via `ProxyProvider`).
- **Persistence**: SharedPreferences (token + cached user; rated job ids for review gating).
- **Networking**: `ApiService` (static `get/post/put`, 15s `.timeout`, JSON decode, list responses wrapped as `{'data': list}`, non-2xx → `ApiException(message)`). Errors surface via provider `_error`; screens show SnackBars.
- **Models**: `Job`/`Handyman`, `User`, `ChatMessage`, `Review` — each with `fromJson` that tolerates Postgres decimal strings (int/num/String casts) and GeoJSON coordinates (`location.coordinates` → lat/lng, longitude-first).
- **Job state in one place**: `JobProvider._jobs` is the source; screen fetches populate it; `_categorizeJobs` buckets into `available` (`matched`), `active` (`accepted|en_route|in_progress|searching`), `completed` (`completed|cancelled`).
- **Socket screen contract**: screens that need room events call `joinJob` in `initState` and register handlers keeping the reference (`_statusHandler`/`_acceptedHandler`/`_foundHandler` in `job_detail_screen.dart`); `dispose` calls `leaveJob` and `off(event, handler)` per handler. `SocketService.off(event, handler)` removes exactly that handler; `off(event)` alone removes all.

### Screen map
- `/` routes by auth state → `LoginScreen`/`HomeScreen`; `/home` after login.
- `HomeScreen`: clients get map + nearby handymen (OpenStreetMap tiles, `MAP_LAT`/`MAP_LNG` overridable) and register global socket listeners; handymen get a dashboard. Logout `disconnect()`s the socket.
- `CreateJobScreen`: posts a job (demo location — `// TODO: Get actual location`).
- `JobListScreen` / `HandymanJobsScreen`: job cards → `JobDetailScreen`.
- `JobDetailScreen`: live status chip + stepper (`_steps` matched→accepted→en_route→in_progress→completed), cancelled banner, description, map, address, prices/timestamps, handyman name, role-aware action card (handyman: Decline/Accept → Start Heading There → Start Work → Chat/Complete; client: Chat while active, Rate Handyman when completed & unrated, "Waiting for a handyman..." spinner while searching/matched). After each action it re-fetches via `fetchJobById`.
- `ChatScreen`: `ChatProvider.loadMessages` + `listenForMessages`.
- `RateJobScreen` → `ReviewProvider.createReview`; `ReviewsScreen` shows "View My Ratings".

## Admin Architecture (Vue 2)

- `admin/src/store/index.js` owns the axios client: baseURL `/api`, 10s timeout, Bearer interceptor (localStorage `handyman_admin_token`), 401 interceptor → clear + redirect `/login` (unless already there). Login action calls `POST /auth/login` and rejects unless `user.role === 'admin'`, then loads stats/users/jobs/reviews.
- Router: `/login` + `requiresAuth` routes; beforeEach redirects unauthenticated users; authenticated users on `/login` go home.
- Views: HomeView (stats from `/admin/stats`), UsersView/JobsView (lists + `PUT` actions; edit modal is a TODO), ReviewsView.
- Build: `vue-cli-service build` → static dist served by nginx with API/socket proxying.

## Docker & Nginx

- Compose services and build stages: `docker-compose.yml`, `backend/Dockerfile` (3-stage: compile `@app/shared`, build backend, slim runtime `node dist/main.js`), `admin/Dockerfile` + `mobile/Dockerfile.web` (builder → nginx:1.27-alpine).
- nginx (admin + mobile-web) proxies `/api/` → `backend:3000/api/` and `/socket.io/` (with upgrade headers) → `backend:3000`; SPA fallback to `/index.html`.
- Mobile-web nginx adds `no-cache` for the Flutter entrypoints (`index.html`, `main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `version.json`) so redeploys aren't masked by stale cache; other static assets cache 7d.
- Backend syncs schema on boot (`DB_SYNCHRONIZE=true` dev); DB volume wipe (`docker compose down -v`) resets seed.

## Troubleshooting Map

| Symptom | Where to look |
|---------|---------------|
| Status changes don't appear on the other side in real time | Real-time emission gap — REST vs socket path (`chat.gateway.ts`, `jobs.service.ts`, `JobProvider`); see `TODO.md` |
| Handyman snackbar doesn't show on match | `emitToUser` requires `register {userId}` to have run; check `SocketService` `register`, or that the matched handyman's socket is connected |
| Detail screen stuck on old status | Screen re-fetches REST after each action (by design); live pushes for status are limited (see gap) |
| Decimal values parse as strings (e.g. backend review/rating) | Postgres `decimal` returns strings; Flutter `fromJson` must cast/parse (see mobile models) |
| Job markers at 0,0 | `Job.fromJson` falls back to 0 when `location` coords absent |
| "Waiting for a handyman" forever | Matching may still be stepping (up to ~170s total) or `matchingFailed` — no UI for matching failure in detail screen today |