# Project Setup

This repository contains a full-stack application with multiple frontend clients.

## Architecture

```
├── backend/       # NestJS API with PostGIS
├── mobile/        # Flutter mobile app
├── admin/         # Vue 2 admin panel
└── shared/        # Shared types and utilities
```

## Quick Start

### Backend (NestJS)
```bash
cd backend
npm install
npm run start:dev
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

### Admin (Vue 2)
```bash
cd admin
npm install
npm run serve
```

## Development

- Follow the conventions outlined in `AGENTS.md`
- Run linting and type checks before committing
- Use feature branches for new development
