# Memory

Remember what matters about the people in your life. Memory is a Next.js web app that connects to Google Contacts and Calendar, lets you take notes about friends, and reminds you via:

- **Note due dates** — optional remind-on date on any note
- **Birthdays & anniversaries** — from synced contact fields
- **Pre-event context** — before calendar events with a contact, surface their recent notes

iOS can reuse the same Supabase backend later; this MVP is web-first.

## Stack

- Next.js (App Router) + TypeScript + Tailwind
- Supabase Auth (Google) + Postgres + RLS
- Google People API + Calendar API (read-only)
- Vercel Cron for reminder materialization + optional Resend email digests

## Setup

### 1. Google Cloud

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **People API** and **Google Calendar API**.
3. Configure OAuth consent screen (External or Internal).
4. Create OAuth client ID type **Web application**.
5. Add authorized redirect URIs for Supabase:
   - `https://<project-ref>.supabase.co/auth/v1/callback`
6. Copy the Client ID and Client Secret.

### 2. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. **Authentication → Providers → Google**: enable and paste Client ID / Secret.
3. Under Google provider **Additional Scopes**, add:
   - `https://www.googleapis.com/auth/contacts.readonly`
   - `https://www.googleapis.com/auth/calendar.readonly`
4. **Authentication → URL Configuration**: set Site URL to `http://localhost:3000` (and production URL later). Add redirect `http://localhost:3000/auth/callback`.
5. Run the SQL migration in the SQL editor:
   - [`supabase/migrations/001_initial_schema.sql`](supabase/migrations/001_initial_schema.sql)

### 3. App env

```bash
cp .env.example .env.local
```

Fill in:

| Variable | Purpose |
| --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role (cron only) |
| `NEXT_PUBLIC_APP_URL` | `http://localhost:3000` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Same as Supabase Google provider (token refresh) |
| `CRON_SECRET` | Shared secret for `/api/cron/reminders` |
| `RESEND_API_KEY` / `RESEND_FROM_EMAIL` | Optional email digests |

### 4. Run locally

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000), sign in with Google (consent to Contacts + Calendar), then **Sync** from Home or Settings.

## Product routes

| Path | Purpose |
| --- | --- |
| `/` | Landing + Google sign-in |
| `/home` | Today’s reminders / first sync |
| `/people` | Searchable contacts |
| `/people/[id]` | Notes + upcoming shared events |
| `/reminders` | Unified reminder feed |
| `/settings` | Sync, event lead time, email digest |

## APIs

- `POST /api/sync` — pull contacts + next 90 days of calendar; rebuild reminders
- `POST|PATCH|DELETE /api/notes` — note CRUD
- `PATCH /api/reminders` — dismiss / update status
- `PATCH /api/settings` — profile preferences
- `GET /api/cron/reminders` — authorized with `Authorization: Bearer $CRON_SECRET`; materializes reminders and sends digests

`vercel.json` schedules that cron hourly.

## Security notes

- All tables use RLS scoped to `auth.uid()`.
- Google scopes are **read-only**.
- Provider tokens are stored on `profiles` for server-side sync; protect the service role key and never expose it to the client.

## Deploy

Deploy to Vercel, set the same env vars, update Supabase Site URL / redirect URLs and Google OAuth authorized origins/redirects for your production domain.
