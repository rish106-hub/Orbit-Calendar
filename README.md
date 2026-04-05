# Orbit Calendar

Orbit Calendar is a narrow MVP for an AI-assisted calendar product with three core flows:

1. Connect Google Calendar
2. Read and modify calendar events through an AI action layer
3. Share one booking link that writes bookings into Google Calendar

Current implementation note:

- OAuth is intentionally skipped for now.
- The app uses local email/password auth with backend-issued bearer sessions.

This repository is organized as a simple monorepo:

- `apps/macos`: native SwiftUI macOS client
- `apps/api`: FastAPI backend
- `docs`: product, architecture, and build docs

## Prerequisites

- Python 3.11+
- Full Xcode 16+ installation for the macOS app

Command Line Tools alone are not sufficient for the native app target. If `xcodebuild -version` fails or Swift reports an SDK mismatch, switch the active developer directory to the full Xcode app before building:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Repository Layout

```text
apps/
  api/
  macos/
docs/
```

## Local Setup

### 1. Create backend virtual environment

```bash
cd apps/api
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

### 2. Copy env files

```bash
cp apps/api/.env.example apps/api/.env
cp apps/macos/Config.example.xcconfig apps/macos/Config.xcconfig
```

## Run the apps

### macOS app

```bash
make macos-run
```

This launches the native SwiftUI shell from `apps/macos`.

If you prefer Xcode, open `apps/macos/Package.swift` directly in Xcode and run the `OrbitCalendarMac` executable target.

### API

```bash
make api-dev
```

The API runs on `http://localhost:8000`.

### Both in parallel

Open two terminals and run:

```bash
make macos-run
```

```bash
make api-dev
```

## Available Commands

- `make macos-run`: run the SwiftUI macOS app
- `make macos-build`: build the SwiftUI macOS app
- `make api-dev`: start the FastAPI server
- `make api-venv`: create the backend virtual environment and install dependencies
- `make api-migrate`: run Alembic migrations against the configured PostgreSQL database

## Database Setup

The backend targets PostgreSQL for the MVP data layer.

1. Copy `apps/api/.env.example` to `apps/api/.env`
2. Update `DATABASE_URL`
3. Create the virtual environment and install backend dependencies:

```bash
make api-venv
```

4. Apply the initial schema:

```bash
make api-migrate
```

The initial migration creates:

- `users`
- `google_accounts`
- `calendars`
- `synced_events`
- `booking_pages`
- `bookings`
- `agent_runs`

## Current Scope

This scaffold intentionally does not implement product logic yet. It only establishes the project structure needed for the MVP build sequence described in:

- `docs/01-mvp-screens-and-flows.md`
- `docs/02-backend-schema-and-tool-contracts.md`
- `docs/03-codex-build-prompts.md`
## Local Auth

The current app flow uses local auth endpoints:

- `POST /api/auth/signup`
- `POST /api/auth/login`
- `POST /api/auth/logout`

Sign up in the macOS client first, then the protected calendar, agent, and booking settings flows unlock automatically.

## Package as DMG

To create an unsigned local `.dmg`:

```bash
./scripts/package_macos_app.sh
```

Output:

- `apps/macos/dist/Orbit-Calendar.dmg`
