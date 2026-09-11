# TODO & Known Issues

Backlog grounded in the current codebase (2026-09-11). Do not mark items done until the referenced code actually changes and is verified.

## Currently Working On

- None — the repository is in a documented rest state after the job-detail-screen feature. This file was created as part of the docs/snapshots task.

## Next (highest-value, backed by confirmed code findings)

1. **Emit socket events from REST job mutations** — `PUT /jobs/:id` (`JobsService.update`) and `PUT /jobs/:id/accept` (`acceptJob`) persist but never emit; the gateway's `updateJobStatus` socket handler is the only emitter of `jobStatusUpdated`, and the Flutter app drives changes via REST. Result: cross-client live status does not work today.
   - Files: `backend/src/modules/jobs/jobs.service.ts`, `backend/src/modules/jobs/jobs.controller.ts`, `backend/src/modules/chat/chat.gateway.ts`, `mobile/lib/providers/job_provider.dart`, `mobile/lib/screens/job_detail_screen.dart`.
   - Before implementing, re-check which events the mobile clients actually listen to (`home_screen.dart`, `job_detail_screen.dart`, `chat_provider.dart`) and preserve `jobOffered`/`newMessage` flows.
2. **Resolve the `jobAccepted` dead event** — `jobAccepted` is listened for (home + detail screens) but never emitted anywhere (0 references in backend). Decide: emit from `acceptJob` with `{jobId, handymanId, handymanName}` or drop the listeners. Do not add a new event name; reuse the one clients already listen to.
3. **Align `handymanFound` payloads** — matching service emits `{ jobId, handymen: [...] }` to the job room, but `job_detail_screen.dart` reads `data['handymanId']`/`data['handymanName']`. Either extend the payload (keep the `handymen` array for backwards compatibility) or update the detail handler.
4. **Scope job reads by role/ownership** — `GET /jobs` and `GET /jobs/:id` return any job (with address) to any authenticated user. Intended behavior should match the app's actual screens (client sees own jobs, handyman sees own + offers) — decide and enforce filtering.
5. **Role-aware status labels for clients** — `jobStatusLabel` in `mobile/lib/app_constants.dart` shows "New Offer" for `matched`, which the client-facing job list shows too (client previously saw "Matched"). Parameterize the label by viewer role or split client/handyman labels.
6. **Action-failure feedback on job detail** — decline/accept/status actions call `await updateJobStatus(...)`/`await acceptJob(...)` then refresh, but no error SnackBar is shown when the provider `_error` is set. Surface failures.

## Later / Nice-to-have

- **Real location in job creation** — `mobile/lib/screens/create_job_screen.dart:101` has `// TODO: Get actual location` (uses demo coordinates).
- **Admin edit-user modal** — `admin/src/views/UsersView.vue:84` has `// TODO: Open edit modal`.
- **Socket reconnect: re-join rooms** — `SocketService` re-emits `register` on reconnect but joined job rooms are not re-entered automatically (screens must call `joinJob` again).
- **Matching-failure UX** — nothing in the detail screen handles `matchingFailed` (client keeps seeing "Waiting for a handyman...").
- **Remove unused `go_router` dependency** — declared in `mobile/pubspec.yaml` but unused (app uses `Navigator`/named routes).
- **Backend automated tests** — jest is configured (`backend/package.json`) but there are no `*.spec.ts` files. Add coverage for `JobsService`, matching, auth, and reviews.
- **CI/CD** — no `.github/`; nothing runs tests/lint/analyze outside the dev machine.
- **Mobile-native build** — repo is Flutter web-focused; Android/iOS runners are not actively built (no Android SDK on dev machine, no `flutter build` in the Docker web image).
- **Docs hygiene** — `mobile/README.md`, `admin/README.md`, `backend/README.md` are short boilerplate; `docker-compose.README.md` predates the `mobile-web` service (table lists 3 services, URLs omit :8081). Keep in sync with root docs.

## Known Issues (verified, not yet triaged)

- **Live status push gap** (core): REST `accept`/`update` don't emit socket events; only the gateway socket handler does. `jobAccepted` never emitted. `handymanFound` payload mismatch. See `ARCHITECTURE.md` → "Real-Time Socket.IO Architecture".
- **Unrestricted job detail exposure**: any authenticated user can read any job including address/prices (`GET /jobs`, `GET /jobs/:id`).
- **Unprotected generic user endpoints**: `GET /users`, `PUT /users/:id`, `DELETE /users/:id` have no role guard (reused by app + admin). Either acceptable as-is (documented) or add `@Roles('admin')` + ownership checks for profile edits.
- **`JobProvider.fetchJobById` uses the global `_isLoading` flag** → can flash list spinners; and `_JobDetailScreenState._refreshing` is only reset when a token exists (guard: `if (auth.token == null) return;` leaves spinner state until first successful fetch — detail screen handles null token by leaving `_refreshing` true).
- **Duplicate socket handler risk**: `home_screen.dart` registers `jobOffered`/etc. listeners in `_initSocket` guarded by `!socket.connected`; screens re-connect + register again in `job_detail_screen.dart`. Ensure `off(event, handler)`-style cleanup and idempotent registrations when screens stack.
- **`SocketService.disconnect()` resets `_userId`**, but if a screen calls `registerUser` after logout race, user-targeted pushes are affected — screens must not register after dispose.
- **Chat listener cleanup**: `ChatProvider.listenForMessages` never calls `socket.off(...)` (only cancels a `StreamSubscription` that isn't used); repeated visits accumulate `newMessage` handlers. Consider `ChatProvider`-level unsubscription using saved handler refs.

## Exact Reference Points

- Add sockets: `backend/src/modules/jobs/jobs.service.ts:66` (`update`), `:88` (`acceptJob`).
- Matching emits: `backend/src/modules/jobs/job-matching.service.ts:117` (`handymanFound` payload `{ jobId, handymen }`), `:124` (`jobOffered`).
- Gateway: `backend/src/modules/chat/chat.gateway.ts` (`updateJobStatus` emits `jobStatusUpdated`, `:167`).
- Detail handler: `mobile/lib/screens/job_detail_screen.dart:82-89` (reads `data['handymanId']`/`handymanName`), `:104` `_refresh`.
- Label: `mobile/lib/app_constants.dart` `jobStatusLabel` (`matched` → "New Offer").
- `JobProvider`: `mobile/lib/providers/job_provider.dart` (`fetchJobById` uses global `_isLoading`, `updateJobFromSocket`).
- TODOs left in code: `mobile/lib/screens/create_job_screen.dart:101`, `admin/src/views/UsersView.vue:84`.
- No socket emit on REST: `backend/src/modules/jobs/jobs.controller.ts` (`PUT` handlers).