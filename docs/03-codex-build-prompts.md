# Orbit Calendar Codex Build Prompts

## How to Use This File

These prompts are sequenced. Run them in order. Do not ask Codex to build the whole product in one shot.

Each prompt assumes:

- The repo starts nearly empty
- The target is a web MVP first unless you explicitly choose macOS native later
- The stack is FastAPI backend plus a modern frontend

If you want the narrowest path to shipping, use:

- Frontend: Next.js
- Backend: FastAPI
- DB: PostgreSQL

## Prompt 1: Repo Foundation

```text
Set up the initial Orbit Calendar MVP monorepo with two apps:
- `apps/web` for the product UI
- `apps/api` for the FastAPI backend

Requirements:
- Use a simple monorepo structure that is easy to run locally
- Add a root README with setup instructions
- Add `.env.example` files for both apps
- Add a `docs/` folder if missing
- Do not implement product logic yet; only scaffold the project
- Add scripts or commands for local development

Return:
- created structure
- commands to run each app
- any assumptions that still need decisions
```

## Prompt 2: Database and Models

```text
Implement the PostgreSQL data layer for Orbit Calendar MVP based on the docs in `docs/02-backend-schema-and-tool-contracts.md`.

Requirements:
- Create migrations for:
  - users
  - google_accounts
  - calendars
  - synced_events
  - booking_pages
  - bookings
  - agent_runs
- Add ORM or SQL model definitions
- Add a database connection module
- Keep the schema tight to the MVP only
- Do not add meeting intelligence or memory tables

Return:
- files changed
- migration names
- how to run migrations locally
```

## Prompt 3: Google OAuth

```text
Implement Google OAuth for Orbit Calendar MVP in the FastAPI backend.

Requirements:
- Add endpoints:
  - `GET /api/auth/google/start`
  - `GET /api/auth/google/callback`
  - `POST /api/auth/logout`
  - `GET /api/me`
- Store Google account metadata securely
- Prepare token refresh support
- Add config entries to `.env.example`
- Use only the minimum scopes needed for reading and writing calendar events
- Add clear error handling for denied consent and invalid callback state

Do not build frontend UI yet beyond what is necessary for callback flow.

Return:
- routes added
- required Google Cloud console setup
- any missing secrets or env vars
```

## Prompt 4: Calendar Sync Service

```text
Implement the Orbit Calendar Google Calendar integration service.

Requirements:
- Fetch the user's calendar list
- Store calendar metadata in the local database
- Add an on-demand sync endpoint:
  - `POST /api/calendar/sync`
- Add a read endpoint:
  - `GET /api/calendar/events?start=...&end=...`
- Normalize Google event payloads into the local event model
- Cache synced events locally
- Keep Google Calendar as the source of truth

Constraints:
- Sync only the requested visible range plus a small buffer
- Handle token refresh if needed
- Keep logs safe; never log raw tokens

Return:
- service and route files
- sync strategy
- how event normalization works
```

## Prompt 5: Scheduling Engine

```text
Implement the MVP scheduling engine for Orbit Calendar.

Requirements:
- Add a service that computes free slots from busy calendar events
- Support:
  - date range
  - duration_minutes
  - selected calendar
- Use the scheduling rules from `docs/02-backend-schema-and-tool-contracts.md`
- Add one internal function or endpoint that returns ranked candidate slots
- Keep ranking simple and deterministic

Do not overbuild:
- no ML
- no energy scoring
- no long-term behavior analysis

Return:
- algorithm summary
- edge cases handled
- how to test it
```

## Prompt 6: Agent Query Endpoint

```text
Implement the Orbit Calendar MVP agent endpoint in FastAPI.

Requirements:
- Add `POST /api/agent/query`
- Support these intents only:
  - `show_schedule`
  - `find_free_time`
  - `create_event`
  - `move_event`
  - `open_booking_settings`
- Use tool-calling style orchestration
- Follow the response contract in `docs/02-backend-schema-and-tool-contracts.md`
- Log each run in `agent_runs`
- For write actions, return a proposed action that requires confirmation instead of executing immediately

Constraints:
- No raw freeform LLM access to Google APIs
- No autonomous writes
- If the request is ambiguous, ask a clarifying question in the response payload

Return:
- intent flow
- tool mapping
- example request and response payloads
```

## Prompt 7: Agent Write Execution

```text
Implement confirmed write execution for Orbit Calendar.

Requirements:
- Add backend handling for approved agent actions
- Support:
  - creating one event
  - moving one event
- Revalidate event targets before writing
- Return updated event data after success
- Ensure user approval is required before any write

Constraints:
- No bulk edits
- No delete action in MVP unless already needed internally

Return:
- endpoint design
- validation logic
- failure cases handled
```

## Prompt 8: Web App Shell

```text
Build the Orbit Calendar web app shell in `apps/web`.

Requirements:
- Implement routes:
  - `/`
  - `/calendar`
  - `/booking`
  - `/settings`
  - `/b/[slug]`
- Follow the product structure in `docs/01-mvp-screens-and-flows.md`
- Main layout must include:
  - top bar
  - main calendar area
  - right-side AI panel
- Keep the design clean and serious, closer to Notion + Linear + Apple Calendar than a chat app

Do not implement every interaction yet; build the shell and major UI blocks first.

Return:
- routes added
- components created
- any placeholder areas still waiting on backend data
```

## Prompt 9: Onboarding and Auth UI

```text
Implement the Orbit Calendar onboarding and auth flow in the web app.

Requirements:
- Build the Onboarding / Sign-in screen from `docs/01-mvp-screens-and-flows.md`
- Connect the Google sign-in CTA to the backend auth start route
- Handle auth success and failure states
- Redirect authenticated users to `/calendar`
- Show a clear trust/privacy note

Return:
- components changed
- state handling
- any unresolved integration gaps
```

## Prompt 10: Calendar Home Data Integration

```text
Connect the Calendar Home screen to live backend data.

Requirements:
- Load calendar events for the visible date range
- Render week view by default
- Support day/week toggle if straightforward
- Refresh events after sync
- Show loading and error states
- Add suggested prompts in the AI panel

Constraints:
- Avoid overcomplicated client state
- Keep the calendar primary and the AI panel secondary

Return:
- data flow
- API calls used
- remaining limitations
```

## Prompt 11: Agent UI Integration

```text
Implement the MVP AI panel and command bar behavior in the web app.

Requirements:
- Add input for natural-language agent requests
- Send requests to `POST /api/agent/query`
- Render agent responses as operational UI, not chat theater
- Add confirmation modal for write actions
- Add support for:
  - read-only result rendering
  - proposed create event action
  - proposed move event action

Return:
- components added
- interaction flow
- how write confirmation works in the UI
```

## Prompt 12: Booking Link Settings

```text
Implement the Booking Link Settings screen for Orbit Calendar.

Requirements:
- Add form fields for:
  - slug
  - title
  - duration
  - working days
  - start/end hours
  - buffer before
  - buffer after
  - minimum notice
- Connect to:
  - `GET /api/booking-page`
  - `PUT /api/booking-page`
- Show a live shareable URL preview

Constraints:
- Support one booking page only
- Do not add multiple event types

Return:
- fields implemented
- validation rules
- backend dependencies
```

## Prompt 13: Public Booking Flow

```text
Implement the public booking page flow for Orbit Calendar.

Requirements:
- Build `/b/[slug]`
- Fetch booking page metadata
- Fetch availability by date and duration
- Let a visitor select a slot and enter:
  - name
  - email
- Submit booking request
- Show success and failure states
- Revalidate availability before confirming booking

Constraints:
- No account required for visitor
- Prevent double booking

Return:
- page behavior
- APIs used
- edge cases handled
```

## Prompt 14: Settings Screen

```text
Implement the Orbit Calendar settings screen.

Requirements:
- Show:
  - display name
  - default timezone
  - connected Google account status
  - selected calendar
- Add sign out
- Add disconnect Google action if backend support exists, otherwise leave a clear placeholder

Return:
- sections built
- actions wired
- anything deferred
```

## Prompt 15: QA and Tightening Pass

```text
Review the Orbit Calendar MVP implementation for scope discipline and product sharpness.

Tasks:
- Remove any features that drift beyond the MVP docs
- Verify every write action requires confirmation
- Verify the booking flow writes into Google Calendar
- Verify the main user can complete:
  - connect Google
  - view schedule
  - ask Orbit for free time
  - create event through Orbit
  - move one event through Orbit
  - create and use one booking link
- Fix broken or inconsistent UX copy
- Add any missing loading, empty, and error states

Return:
- findings
- fixes made
- residual risks
```

## Build Sequence Summary

Use the prompts in this order:

1. Repo foundation
2. Database and models
3. Google OAuth
4. Calendar sync service
5. Scheduling engine
6. Agent query endpoint
7. Agent write execution
8. Web app shell
9. Onboarding and auth UI
10. Calendar home data integration
11. Agent UI integration
12. Booking link settings
13. Public booking flow
14. Settings screen
15. QA and tightening pass

## Guardrails

- Keep the MVP strict
- Do not add meeting intelligence yet
- Do not add vector memory yet
- Do not add autonomous calendar edits
- Do not turn the AI panel into a generic chatbot
- Optimize for fewer clicks, not feature count
