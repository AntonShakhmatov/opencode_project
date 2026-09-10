# Project Instructions

## Overview

This project uses OpenCode as its AI development assistant. OpenCode is configured via `opencode.json` in the project root.

## Tech Stack

- **Backend**: NestJS (TypeScript)
- **Database**: PostgreSQL with PostGIS extension
- **Mobile Frontend**: Flutter (Dart)
- **Admin Panel**: Vue 2

## Conventions

- Follow existing code style and naming conventions when making changes.
- Do not modify files inside the `.opencode/` directory (Python virtual environment).
- Keep changes focused and minimal.
- Prefer editing existing files over creating new ones unless necessary.

### NestJS Backend
- Use dependency injection and modular architecture
- Follow NestJS conventions for controllers, services, and modules
- Use TypeORM or Prisma for database operations

### Flutter Frontend
- Follow Dart style guide and Flutter best practices
- Use state management solutions (Provider, Bloc, or Riverpod)

### Vue 2 Admin
- Follow Vue 2 style guide
- Use Vuex for state management

## Verification

- Run available lint and typecheck commands before considering work complete.
- If no lint or test commands exist, verify changes manually.