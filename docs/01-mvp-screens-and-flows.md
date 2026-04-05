# Orbit Calendar MVP

## Goal

Ship a narrow MVP that lets a user:

1. Connect Google Calendar
2. Read and modify calendar data through an AI action panel
3. Share one booking link that writes bookings into Google Calendar

Success condition:

- A user can schedule or reschedule something in under 30 seconds without opening Google Calendar.

Non-goals for MVP:

- Meeting recording
- Meeting transcription
- Meeting summaries
- Long-term memory engine
- Time optimization score
- Autonomous weekly optimization
- Multi-calendar analytics beyond basic availability computation

## Product Structure

The MVP has 5 screens and 2 overlays.

Primary screens:

1. Onboarding / Sign-in
2. Calendar Home
3. Booking Link Settings
4. Public Booking Page
5. Settings

Overlays:

1. Command Bar
2. Agent Confirmation Modal

## Screen 1: Onboarding / Sign-in

Purpose:

- Get the user authenticated
- Request Google Calendar permissions
- Explain the product in one sentence

Layout:

- Left: product statement and 3 short capabilities
- Right: sign in card

Content:

- Product name: Orbit Calendar
- Headline: "AI that helps you act on your calendar"
- Subtext: "Connect Google Calendar, ask Orbit to find time, and let it schedule for you."
- Primary CTA: "Continue with Google"
- Secondary note: "We only access your calendar to read availability and create or edit events you approve."

States:

- Default
- OAuth loading
- OAuth failed
- Permissions denied
- Connected successfully

User actions:

- Click Google sign-in
- Retry if OAuth fails
- Continue to Calendar Home on success

Acceptance criteria:

- User can authenticate with Google
- App stores Google identity and token metadata securely
- App confirms at least one Google Calendar account is available

## Screen 2: Calendar Home

Purpose:

- Main workspace for daily use
- Combine calendar visibility with agent actions

Layout:

- Top bar
- Left/main: calendar
- Right rail: AI panel

Top bar:

- Orbit logo
- Current date range
- Global command trigger
- "Booking Link" button
- Settings button

Main calendar region:

- Default view: week view
- Optional toggle: day / week
- Event cards rendered from synced Google events
- Free-time gaps visually distinct but subtle
- Current time indicator

Right AI panel:

- Header: "Ask Orbit"
- Suggested prompts:
  - "What does my day look like?"
  - "Find 2 hours for deep work tomorrow"
  - "Move my lowest priority meeting to next week"
  - "When am I free this week for a 30 minute call?"
- Input box
- Response stream area
- Action summary area

Core interaction model:

- User asks in natural language
- Orbit parses intent
- Orbit shows what it plans to do
- If write action is required, Orbit asks for confirmation
- After confirmation, Orbit executes and refreshes calendar state

States:

- Empty calendar
- Syncing calendar
- Normal loaded state
- Tool execution in progress
- Action requires approval
- Action failed with recovery message

Acceptance criteria:

- Calendar loads events from Google for the selected range
- Agent can answer read-only questions without leaving the screen
- Agent can create or move events after explicit confirmation
- Calendar view refreshes after successful write operations

## Screen 3: Booking Link Settings

Purpose:

- Let a user configure one shareable booking page

Layout:

- Left: booking configuration form
- Right: live preview summary

Settings supported in MVP:

- Public slug
- Meeting title
- Meeting duration options:
  - 15 min
  - 30 min
  - 60 min
- Availability window:
  - weekdays enabled
  - start/end hours
- Buffer before meeting
- Buffer after meeting
- Minimum notice
- Booking timezone behavior:
  - auto-detect visitor timezone

Not in MVP:

- Round robin
- Team scheduling
- Custom intake forms beyond name and email
- Payment collection
- Multiple event types

Actions:

- Save booking settings
- Copy shareable link
- Disable booking link

Acceptance criteria:

- User can generate one public booking URL
- Backend can compute availability from Google Calendar + rules
- Saving settings updates future public availability immediately

## Screen 4: Public Booking Page

Purpose:

- Let an external person book a meeting into the user's calendar

Layout:

- Left: host info, meeting title, duration, timezone
- Right: date picker + available times

Displayed data:

- Host display name
- Meeting title
- Selected duration
- Visitor timezone label
- Available slots based on:
  - Google busy events
  - working hours
  - buffers
  - minimum notice

Booking form:

- Name
- Email
- Confirm booking

Success state:

- Booking confirmed
- Calendar invite created
- Slot removed from availability

Error states:

- Slot just got booked
- Google sync failure
- Link disabled
- Invalid slug

Acceptance criteria:

- Visitor can book without account creation
- Booking creates a Google Calendar event for the host
- Double booking is prevented server-side

## Screen 5: Settings

Purpose:

- Account and integration management

Sections:

- Profile
- Connected Google account
- Calendar preferences
- Privacy note
- Sign out

MVP fields:

- Display name
- Default timezone
- Default calendar target
- Google connection status

Acceptance criteria:

- User can inspect connected account and active calendar
- User can disconnect Google
- User timezone can be changed

## Overlay 1: Command Bar

Purpose:

- Faster action entry than using the side panel

Trigger:

- Keyboard shortcut
- Top bar button

Supported commands in MVP:

- "Show my schedule today"
- "Find free time tomorrow"
- "Create focus block tomorrow at 2 PM"
- "Move my 4 PM meeting to Friday"
- "Open booking settings"

Behavior:

- Read-only requests can return inline results
- Write requests open confirmation modal before execution

## Overlay 2: Agent Confirmation Modal

Purpose:

- Prevent silent calendar mutations

Shown for:

- Create event
- Update event
- Delete event if added later

Contents:

- Plain-language action summary
- Event details before/after
- Target calendar
- Confirm / Cancel

Rule:

- No write action occurs without explicit approval in MVP

## User Flows

### Flow 1: First-time setup

1. User lands on Onboarding
2. User clicks "Continue with Google"
3. OAuth completes
4. App requests calendar scopes
5. App loads default calendar metadata
6. User enters Calendar Home

Definition of done:

- User sees synced events in week view within one session

### Flow 2: Ask a read-only question

Example:

"When am I free for 2 hours tomorrow?"

1. User types request in AI panel
2. Agent identifies `find_free_time`
3. Backend reads events for tomorrow
4. Scheduling logic computes free blocks
5. Agent returns options in natural language
6. Calendar stays unchanged

Definition of done:

- User gets valid free slots with no action approval step

### Flow 3: Create an event through Orbit

Example:

"Block deep work tomorrow from 10 to 12"

1. User enters request
2. Agent identifies `create_event`
3. Agent resolves target time and calendar
4. Agent shows confirmation modal
5. User confirms
6. Backend writes event to Google Calendar
7. Calendar refetches and renders new event
8. Agent shows success message

Definition of done:

- Event appears both in Orbit and Google Calendar

### Flow 4: Move an existing event

Example:

"Move my lowest priority meeting to next week"

MVP simplification:

- The system only supports moving one matched event at a time.
- If the user says "all", Orbit responds with ranked suggestions but does not bulk-edit in MVP.

Flow:

1. User requests move
2. Agent identifies candidate event
3. Agent computes suggested destination slots
4. Agent presents proposed move
5. User confirms
6. Backend updates Google Calendar event
7. Calendar refreshes

Definition of done:

- One existing event is rescheduled safely with user approval

### Flow 5: Create and use booking link

Host setup:

1. User opens Booking Link Settings
2. User defines slug, duration, hours, buffers
3. User saves and copies link

Visitor booking:

1. Visitor opens public booking page
2. System detects timezone
3. Visitor selects date and slot
4. Visitor enters name and email
5. Backend revalidates slot availability
6. Backend creates Google Calendar event
7. Visitor sees confirmation

Definition of done:

- A booking appears on the host's calendar with no manual intervention

## MVP Permissions and Trust Rules

- Read-only requests execute immediately
- Any calendar write requires explicit user confirmation
- Public bookings can create events without manual host approval because they are constrained by booking rules
- Orbit must always explain the action it is taking in plain language

## Information Architecture

- `/` -> onboarding or calendar home depending on auth
- `/calendar` -> main app
- `/booking` -> booking settings
- `/b/:slug` -> public booking page
- `/settings` -> account settings

## Design Direction

Visual reference:

- Notion clarity
- Linear density
- Apple Calendar calmness

Rules:

- Keep the calendar visually primary
- Keep AI interaction contextual, not dominant
- Use strong typography and restrained color
- Avoid chat-app aesthetics
- Treat agent output as operational UI, not conversation theater

## MVP Constraints That Must Stay Tight

- One connected provider: Google Calendar only
- One booking link type
- One user account type
- No bulk calendar edits
- No autonomous edits without approval
- No meeting intelligence in initial release
