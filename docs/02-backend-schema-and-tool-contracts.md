# Orbit Calendar Backend Spec

## Objective

Define the minimum backend, data model, and agent tool contracts required to support the MVP flows:

1. Google auth and calendar sync
2. Calendar read and write through an agent layer
3. One public booking link

The stack assumption for this spec:

- Backend: FastAPI
- Database: PostgreSQL
- Embeddings/vector memory: not required for MVP
- LLM: OpenAI with tool calling

## System Boundaries

Backend responsibilities:

- Manage auth session state
- Store Google connection metadata
- Read and write Google Calendar events
- Normalize calendar events into app-friendly models
- Compute free time and booking availability
- Expose agent-safe tool endpoints
- Create public bookings

Out of scope:

- WebSocket-heavy collaboration
- Background meeting transcription pipeline
- Multi-provider calendars
- Multi-tenant org features

## Service Modules

### 1. Auth Service

Responsibilities:

- Google OAuth start and callback
- Session issuance
- Token encryption at rest
- Refresh token lifecycle

### 2. Calendar Service

Responsibilities:

- Fetch calendar list
- Fetch events by time range
- Create event
- Update event
- Normalize Google payloads

### 3. Scheduling Service

Responsibilities:

- Compute busy intervals
- Compute free slots
- Apply booking rules
- Rank candidate slots

### 4. Agent Service

Responsibilities:

- Accept natural-language requests from app UI
- Build tool context
- Execute tool calls
- Return structured action proposals and results

### 5. Booking Service

Responsibilities:

- Store booking configuration
- Expose public availability
- Revalidate slots
- Create booked event

## Core Data Model

### users

Purpose:

- Primary local user record

Fields:

- `id` UUID PK
- `email` text unique not null
- `display_name` text
- `default_timezone` text not null
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

### google_accounts

Purpose:

- Connected Google identity and OAuth metadata

Fields:

- `id` UUID PK
- `user_id` UUID FK -> users.id
- `google_subject` text not null
- `email` text not null
- `access_token_encrypted` text not null
- `refresh_token_encrypted` text
- `token_expires_at` timestamptz
- `scopes` text[] not null
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

Constraints:

- unique(`user_id`)
- unique(`google_subject`)

### calendars

Purpose:

- Cached metadata for Google calendars visible to the user

Fields:

- `id` UUID PK
- `user_id` UUID FK -> users.id
- `google_calendar_id` text not null
- `summary` text not null
- `primary_calendar` boolean not null default false
- `selected_for_scheduling` boolean not null default false
- `timezone` text
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

Constraints:

- unique(`user_id`, `google_calendar_id`)

### synced_events

Purpose:

- Local cache of Google Calendar events for fast reads and scheduling logic

Fields:

- `id` UUID PK
- `user_id` UUID FK -> users.id
- `calendar_id` UUID FK -> calendars.id
- `google_event_id` text not null
- `title` text
- `description` text
- `status` text not null
- `starts_at` timestamptz not null
- `ends_at` timestamptz not null
- `all_day` boolean not null default false
- `location` text
- `meeting_url` text
- `raw_payload` jsonb not null
- `last_synced_at` timestamptz not null
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

Constraints:

- unique(`calendar_id`, `google_event_id`)

Note:

- This is a cache, not the source of truth. Google Calendar remains the source of truth.

### booking_pages

Purpose:

- One public booking configuration per user in MVP

Fields:

- `id` UUID PK
- `user_id` UUID FK -> users.id
- `slug` text unique not null
- `title` text not null
- `active` boolean not null default true
- `default_duration_minutes` integer not null
- `working_days` integer[] not null
- `day_start_local` time not null
- `day_end_local` time not null
- `buffer_before_minutes` integer not null default 0
- `buffer_after_minutes` integer not null default 0
- `minimum_notice_minutes` integer not null default 0
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

### bookings

Purpose:

- Track bookings made via the public page

Fields:

- `id` UUID PK
- `booking_page_id` UUID FK -> booking_pages.id
- `user_id` UUID FK -> users.id
- `visitor_name` text not null
- `visitor_email` text not null
- `visitor_timezone` text not null
- `starts_at` timestamptz not null
- `ends_at` timestamptz not null
- `google_event_id` text
- `status` text not null
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

Suggested statuses:

- `pending`
- `confirmed`
- `failed`
- `cancelled`

### agent_runs

Purpose:

- Operational logging for agent requests and tool use

Fields:

- `id` UUID PK
- `user_id` UUID FK -> users.id
- `input_text` text not null
- `detected_intent` text
- `status` text not null
- `tool_trace` jsonb
- `result_summary` text
- `created_at` timestamptz not null
- `updated_at` timestamptz not null

## Minimal SQL Sketch

```sql
create table users (
  id uuid primary key,
  email text unique not null,
  display_name text,
  default_timezone text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table google_accounts (
  id uuid primary key,
  user_id uuid not null references users(id) on delete cascade,
  google_subject text unique not null,
  email text not null,
  access_token_encrypted text not null,
  refresh_token_encrypted text,
  token_expires_at timestamptz,
  scopes text[] not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  unique(user_id)
);

create table calendars (
  id uuid primary key,
  user_id uuid not null references users(id) on delete cascade,
  google_calendar_id text not null,
  summary text not null,
  primary_calendar boolean not null default false,
  selected_for_scheduling boolean not null default false,
  timezone text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  unique(user_id, google_calendar_id)
);

create table synced_events (
  id uuid primary key,
  user_id uuid not null references users(id) on delete cascade,
  calendar_id uuid not null references calendars(id) on delete cascade,
  google_event_id text not null,
  title text,
  description text,
  status text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  all_day boolean not null default false,
  location text,
  meeting_url text,
  raw_payload jsonb not null,
  last_synced_at timestamptz not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  unique(calendar_id, google_event_id)
);

create table booking_pages (
  id uuid primary key,
  user_id uuid not null references users(id) on delete cascade,
  slug text unique not null,
  title text not null,
  active boolean not null default true,
  default_duration_minutes integer not null,
  working_days integer[] not null,
  day_start_local time not null,
  day_end_local time not null,
  buffer_before_minutes integer not null default 0,
  buffer_after_minutes integer not null default 0,
  minimum_notice_minutes integer not null default 0,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table bookings (
  id uuid primary key,
  booking_page_id uuid not null references booking_pages(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  visitor_name text not null,
  visitor_email text not null,
  visitor_timezone text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  google_event_id text,
  status text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table agent_runs (
  id uuid primary key,
  user_id uuid not null references users(id) on delete cascade,
  input_text text not null,
  detected_intent text,
  status text not null,
  tool_trace jsonb,
  result_summary text,
  created_at timestamptz not null,
  updated_at timestamptz not null
);
```

## API Surface

### Auth

- `GET /api/auth/google/start`
- `GET /api/auth/google/callback`
- `POST /api/auth/logout`
- `GET /api/me`

### Calendar App APIs

- `GET /api/calendar/events?start=...&end=...`
- `POST /api/calendar/sync`
- `POST /api/agent/query`
- `GET /api/booking-page`
- `PUT /api/booking-page`

### Public Booking APIs

- `GET /api/public/booking-pages/{slug}`
- `GET /api/public/booking-pages/{slug}/availability?date=YYYY-MM-DD&duration=30`
- `POST /api/public/booking-pages/{slug}/book`

## Scheduling Model

Inputs:

- Busy events from selected calendar
- Booking page rules
- User timezone
- Requested duration
- Optional preferred windows

Algorithm for MVP:

1. Expand busy intervals for the date range
2. Apply buffers around busy intervals
3. Clip to allowed working hours
4. Remove slots violating minimum notice
5. Return discrete candidate slots

Ranking heuristics for MVP:

- Prefer earlier available slots
- Prefer windows with at least 15 minutes of margin before and after
- Avoid lunch window only if user config exists later; omit for MVP

## Agent Layer

This must be a tool-using action agent, not freeform chat.

### Supported intents in MVP

- `show_schedule`
- `find_free_time`
- `create_event`
- `move_event`
- `open_booking_settings`

### Response contract from `/api/agent/query`

```json
{
  "run_id": "uuid",
  "intent": "create_event",
  "message": "I found a free block tomorrow from 10:00 AM to 12:00 PM and can schedule Deep Work there.",
  "requires_confirmation": true,
  "proposed_action": {
    "tool_name": "calendar_create_event",
    "arguments": {
      "title": "Deep Work",
      "start": "2026-04-06T10:00:00+05:30",
      "end": "2026-04-06T12:00:00+05:30",
      "calendar_id": "primary"
    }
  },
  "data": {
    "candidate_slots": [
      {
        "start": "2026-04-06T10:00:00+05:30",
        "end": "2026-04-06T12:00:00+05:30"
      }
    ]
  }
}
```

### Confirmation model

For any write action:

1. Agent returns `requires_confirmation: true`
2. Client shows approval modal
3. Client submits approved tool execution to backend
4. Backend executes
5. Backend returns success/failure and refreshed entities

## Tool Contracts

These are internal agent tools exposed to the LLM orchestration layer, not public APIs.

### 1. `calendar_read_events`

Purpose:

- Fetch normalized events in a time window

Input:

```json
{
  "start": "ISO-8601 datetime",
  "end": "ISO-8601 datetime",
  "calendar_id": "primary | uuid | null"
}
```

Output:

```json
{
  "events": [
    {
      "event_id": "evt_123",
      "title": "Standup",
      "start": "2026-04-06T09:00:00+05:30",
      "end": "2026-04-06T09:30:00+05:30",
      "status": "confirmed"
    }
  ]
}
```

### 2. `calendar_find_free_slots`

Purpose:

- Compute candidate free slots for a duration and range

Input:

```json
{
  "range_start": "ISO-8601 datetime",
  "range_end": "ISO-8601 datetime",
  "duration_minutes": 120,
  "calendar_id": "primary | uuid | null"
}
```

Output:

```json
{
  "slots": [
    {
      "start": "2026-04-06T10:00:00+05:30",
      "end": "2026-04-06T12:00:00+05:30",
      "score": 0.92
    }
  ]
}
```

### 3. `calendar_create_event`

Purpose:

- Create a Google Calendar event

Input:

```json
{
  "calendar_id": "primary | uuid",
  "title": "Deep Work",
  "start": "2026-04-06T10:00:00+05:30",
  "end": "2026-04-06T12:00:00+05:30",
  "description": "Optional",
  "location": "Optional"
}
```

Output:

```json
{
  "success": true,
  "event": {
    "event_id": "evt_456",
    "title": "Deep Work",
    "start": "2026-04-06T10:00:00+05:30",
    "end": "2026-04-06T12:00:00+05:30"
  }
}
```

### 4. `calendar_move_event`

Purpose:

- Update one existing event time

Input:

```json
{
  "event_id": "evt_123",
  "new_start": "2026-04-10T16:00:00+05:30",
  "new_end": "2026-04-10T16:30:00+05:30"
}
```

Output:

```json
{
  "success": true,
  "event": {
    "event_id": "evt_123",
    "title": "Weekly Sync",
    "start": "2026-04-10T16:00:00+05:30",
    "end": "2026-04-10T16:30:00+05:30"
  }
}
```

### 5. `booking_get_configuration`

Purpose:

- Read booking page settings for the signed-in user

Input:

```json
{}
```

Output:

```json
{
  "slug": "akash",
  "title": "Intro Meeting",
  "default_duration_minutes": 30,
  "working_days": [1, 2, 3, 4, 5],
  "day_start_local": "09:00:00",
  "day_end_local": "18:00:00"
}
```

### 6. `booking_compute_public_availability`

Purpose:

- Return available slots for public booking page

Input:

```json
{
  "slug": "akash",
  "date": "2026-04-10",
  "duration_minutes": 30,
  "visitor_timezone": "America/New_York"
}
```

Output:

```json
{
  "timezone": "America/New_York",
  "slots": [
    {
      "start": "2026-04-10T11:30:00-04:00",
      "end": "2026-04-10T12:00:00-04:00"
    }
  ]
}
```

### 7. `booking_create_reservation`

Purpose:

- Create a booking after availability recheck

Input:

```json
{
  "slug": "akash",
  "visitor_name": "Sam Lee",
  "visitor_email": "sam@example.com",
  "visitor_timezone": "America/New_York",
  "start": "2026-04-10T11:30:00-04:00",
  "end": "2026-04-10T12:00:00-04:00"
}
```

Output:

```json
{
  "success": true,
  "booking_id": "bk_123",
  "host_event_id": "evt_789"
}
```

## LLM Orchestration Rules

- Never allow the LLM to call Google APIs directly
- The LLM only sees normalized tool schemas
- All date parsing should be resolved server-side with the user's timezone
- Any ambiguous write intent should return clarification instead of guessing
- Any write tool requires confirmation before execution

## Example Agent Execution

User input:

"Schedule 2 hours of deep work tomorrow afternoon"

Execution:

1. Parse intent as `find_free_time` plus potential `create_event`
2. Resolve "tomorrow afternoon" in user timezone
3. Call `calendar_find_free_slots`
4. Choose top slot
5. Return proposal with `requires_confirmation: true`
6. On approval, call `calendar_create_event`

## Security and Privacy Requirements

- Encrypt OAuth tokens at rest
- Store only minimum required Google metadata
- Log tool actions, not raw token values
- Require authenticated session for all app APIs
- Rate limit public booking endpoints
- Recheck slot availability transactionally before final booking write

## Operational Notes

- Use background sync sparingly; prioritize on-demand sync by visible date range
- Cache normalized events locally to reduce repeated Google reads
- Add idempotency key support for booking creation to prevent duplicate submits
- Record agent tool traces for debugging false actions

## MVP Tradeoffs

- No vector database yet
- No memory retrieval tool yet
- No recurring-rule editing from the agent in v1
- No bulk event moves
- No multi-calendar conflict resolution UI beyond a selected calendar strategy
