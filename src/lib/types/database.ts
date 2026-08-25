export type ReminderType = "note_due" | "birthday" | "anniversary" | "pre_event";
export type ReminderStatus = "pending" | "sent" | "dismissed";

export type Profile = {
  id: string;
  email: string | null;
  full_name: string | null;
  avatar_url: string | null;
  google_access_token: string | null;
  google_refresh_token: string | null;
  google_token_expires_at: string | null;
  event_reminder_hours: number;
  email_digest_enabled: boolean;
  created_at: string;
  updated_at: string;
};

export type Contact = {
  id: string;
  user_id: string;
  google_resource_name: string;
  display_name: string | null;
  given_name: string | null;
  family_name: string | null;
  emails: string[];
  phones: string[];
  photo_url: string | null;
  birthday_month: number | null;
  birthday_day: number | null;
  birthday_year: number | null;
  anniversary_month: number | null;
  anniversary_day: number | null;
  anniversary_year: number | null;
  raw: unknown;
  created_at: string;
  updated_at: string;
};

export type CalendarEvent = {
  id: string;
  user_id: string;
  google_event_id: string;
  calendar_id: string;
  title: string | null;
  description: string | null;
  location: string | null;
  starts_at: string | null;
  ends_at: string | null;
  all_day: boolean;
  attendee_emails: string[];
  raw: unknown;
  created_at: string;
  updated_at: string;
};

export type ContactNote = {
  id: string;
  user_id: string;
  contact_id: string;
  body: string;
  tags: string[];
  remind_at: string | null;
  created_at: string;
  updated_at: string;
};

export type Reminder = {
  id: string;
  user_id: string;
  type: ReminderType;
  status: ReminderStatus;
  due_at: string;
  title: string;
  body: string | null;
  contact_id: string | null;
  note_id: string | null;
  event_id: string | null;
  dedupe_key: string;
  created_at: string;
};

export type SyncState = {
  user_id: string;
  contacts_synced_at: string | null;
  calendar_synced_at: string | null;
  contacts_sync_token: string | null;
  calendar_sync_token: string | null;
  last_error: string | null;
  updated_at: string;
};

export type ReminderWithRelations = Reminder & {
  contacts?: Pick<Contact, "id" | "display_name" | "photo_url"> | null;
  contact_notes?: Pick<ContactNote, "id" | "body"> | null;
  calendar_events?: Pick<CalendarEvent, "id" | "title" | "starts_at"> | null;
};
