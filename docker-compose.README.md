# Handyman - Backend + Admin Docker

Build and run the full stack (Postgres+PostGIS, NestJS API, Vue admin) with Docker Compose.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with Docker Compose v2+
  - Linux: `docker` + `docker compose`
  - Windows: Docker Desktop (with WSL2 backend)

## Quick start

```bash
docker compose up --build -d
```

Wait for the stack to be ready (first build pulls images and installs deps):

```bash
docker compose logs -f backend
```

When you see `Server running on http://localhost:3000`, the stack is up.

## Services

| Service   | Container name    | URL                        | Description                    |
|-----------|-------------------|----------------------------|--------------------------------|
| db        | `handyman-db`     | localhost:5432             | PostgreSQL 16 + PostGIS 3.4    |
| backend   | `handyman-backend`| http://localhost:3000/api  | NestJS REST + WebSocket API    |
| admin     | `handyman-admin`  | http://localhost:8080      | Vue 2 admin dashboard          |

## URLs

- **Admin dashboard**: http://localhost:8080
- **API test page**: http://localhost:8080/test.html
- **API health check**: http://localhost:3000/api (or http://localhost:8080/api/)

## Seed data (auto-created on first run)

All users share password `password123`:

| Role     | Email                          |
|----------|--------------------------------|
| Admin    | `admin@handyman.com`           |
| Client   | `client@test.com`, `client2@test.com` |
| Handyman | `plumber@test.com`, `electrician@test.com`, `carpenter@test.com`, `cleaner@test.com` |

Seeding only runs when the users table is empty.

## Common commands

```bash
# Stop all containers (data persists in the volume)
docker compose down

# Stop and wipe the database volume
docker compose down -v

# Rebuild after code changes
docker compose up --build -d

# View logs
docker compose logs -f backend
docker compose logs -f admin

# Run only the database (for local dev)
docker compose up -d db
```

## Configuration (docker-compose.yml)

- Database name: `handyman_db`, user/pass: `postgres`/`postgres`
- Backend auto-syncs the schema on startup (`DB_SYNCHRONIZE=true`)
- Admin nginx proxies `/api/` and `/socket.io/` to the backend service

## Notes

- Schema and seed data are managed automatically; wipe the volume (`docker compose down -v`) to reset.
- Ports can be changed in `docker-compose.yml` (e.g. `"3000:3000"` → `"4000:3000"`).