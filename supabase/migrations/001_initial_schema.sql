-- Memory app schema + RLS
-- Run in Supabase SQL editor or via supabase db push

create extension if not exists "pgcrypto";

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  avatar_url text,
  google_access_token text,
  google_refresh_token text,
  google_token_expires_at timestamptz,
  event_reminder_hours integer not null default 24,
  email_digest_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Synced Google contacts
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  google_resource_name text not null,
  display_name text,
  given_name text,
  family_name text,
  emails text[] not null default '{}',
  phones text[] not null default '{}',
  photo_url text,
  birthday_month integer,
  birthday_day integer,
  birthday_year integer,
  anniversary_month integer,
  anniversary_day integer,
  anniversary_year integer,
  raw jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, google_resource_name)
);

create index if not exists contacts_user_id_idx on public.contacts (user_id);
create index if not exists contacts_emails_idx on public.contacts using gin (emails);

-- Synced calendar events
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  google_event_id text not null,
  calendar_id text not null default 'primary',
  title text,
  description text,
  location text,
  starts_at timestamptz,
  ends_at timestamptz,
  all_day boolean not null default false,
  attendee_emails text[] not null default '{}',
  raw jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, google_event_id)
);

create index if not exists calendar_events_user_starts_idx
  on public.calendar_events (user_id, starts_at);

-- Notes about friends
create table if not exists public.contact_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contact_id uuid not null references public.contacts (id) on delete cascade,
  body text not null,
  tags text[] not null default '{}',
  remind_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists contact_notes_contact_id_idx on public.contact_notes (contact_id);
create index if not exists contact_notes_remind_at_idx on public.contact_notes (user_id, remind_at);

-- Unified reminder queue
do $$ begin
  create type public.reminder_type as enum (
    'note_due',
    'birthday',
    'anniversary',
    'pre_event'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.reminder_status as enum (
    'pending',
    'sent',
    'dismissed'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type public.reminder_type not null,
  status public.reminder_status not null default 'pending',
  due_at timestamptz not null,
  title text not null,
  body text,
  contact_id uuid references public.contacts (id) on delete cascade,
  note_id uuid references public.contact_notes (id) on delete cascade,
  event_id uuid references public.calendar_events (id) on delete cascade,
  dedupe_key text not null,
  created_at timestamptz not null default now(),
  unique (user_id, dedupe_key)
);

create index if not exists reminders_user_due_idx
  on public.reminders (user_id, due_at, status);

-- Sync bookkeeping
create table if not exists public.sync_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  contacts_synced_at timestamptz,
  calendar_synced_at timestamptz,
  contacts_sync_token text,
  calendar_sync_token text,
  last_error text,
  updated_at timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
    updated_at = now();
  insert into public.sync_state (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.contacts enable row level security;
alter table public.calendar_events enable row level security;
alter table public.contact_notes enable row level security;
alter table public.reminders enable row level security;
alter table public.sync_state enable row level security;

-- Profiles policies
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- Contacts
create policy "contacts_all_own" on public.contacts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Calendar events
create policy "calendar_events_all_own" on public.calendar_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Notes
create policy "contact_notes_all_own" on public.contact_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Reminders
create policy "reminders_all_own" on public.reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Sync state
create policy "sync_state_all_own" on public.sync_state
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
