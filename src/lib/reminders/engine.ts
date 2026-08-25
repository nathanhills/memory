import type { SupabaseClient } from "@supabase/supabase-js";
import {
  addDays,
  format,
  isBefore,
  setHours,
  setMinutes,
  setSeconds,
  setMilliseconds,
  startOfDay,
} from "date-fns";
import type {
  CalendarEvent,
  Contact,
  ContactNote,
  Profile,
  ReminderType,
} from "@/lib/types/database";

type ReminderInsert = {
  user_id: string;
  type: ReminderType;
  status: "pending";
  due_at: string;
  title: string;
  body: string | null;
  contact_id: string | null;
  note_id: string | null;
  event_id: string | null;
  dedupe_key: string;
};

function nextOccurrence(
  month: number,
  day: number,
  from: Date,
): Date | null {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  const year = from.getFullYear();
  let candidate = new Date(year, month - 1, day, 9, 0, 0, 0);
  if (isBefore(candidate, startOfDay(from))) {
    candidate = new Date(year + 1, month - 1, day, 9, 0, 0, 0);
  }
  return candidate;
}

function morningOf(date: Date) {
  return setMilliseconds(
    setSeconds(setMinutes(setHours(date, 9), 0), 0),
    0,
  );
}

export async function materializeRemindersForUser(
  supabase: SupabaseClient,
  userId: string,
) {
  const [{ data: profile }, { data: contacts }, { data: notes }, { data: events }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", userId).maybeSingle(),
      supabase.from("contacts").select("*").eq("user_id", userId),
      supabase.from("contact_notes").select("*").eq("user_id", userId),
      supabase
        .from("calendar_events")
        .select("*")
        .eq("user_id", userId)
        .gte("starts_at", new Date().toISOString())
        .lte("starts_at", addDays(new Date(), 30).toISOString()),
    ]);

  const p = profile as Profile | null;
  const leadHours = p?.event_reminder_hours ?? 24;
  const contactList = (contacts ?? []) as Contact[];
  const noteList = (notes ?? []) as ContactNote[];
  const eventList = (events ?? []) as CalendarEvent[];

  const emailToContact = new Map<string, Contact>();
  for (const c of contactList) {
    for (const email of c.emails ?? []) {
      emailToContact.set(email.toLowerCase(), c);
    }
  }

  const inserts: ReminderInsert[] = [];
  const now = new Date();

  // Note due reminders
  for (const note of noteList) {
    if (!note.remind_at) continue;
    const contact = contactList.find((c) => c.id === note.contact_id);
    inserts.push({
      user_id: userId,
      type: "note_due",
      status: "pending",
      due_at: note.remind_at,
      title: `Remember for ${contact?.display_name ?? "a friend"}`,
      body: note.body,
      contact_id: note.contact_id,
      note_id: note.id,
      event_id: null,
      dedupe_key: `note_due:${note.id}:${note.remind_at}`,
    });
  }

  // Birthdays & anniversaries (next occurrence within 30 days)
  const horizon = addDays(now, 30);
  for (const contact of contactList) {
    if (contact.birthday_month && contact.birthday_day) {
      const due = nextOccurrence(
        contact.birthday_month,
        contact.birthday_day,
        now,
      );
      if (due && !isBefore(horizon, due)) {
        inserts.push({
          user_id: userId,
          type: "birthday",
          status: "pending",
          due_at: morningOf(due).toISOString(),
          title: `${contact.display_name ?? "Someone"}'s birthday`,
          body: `Wish ${contact.display_name ?? "them"} a happy birthday.`,
          contact_id: contact.id,
          note_id: null,
          event_id: null,
          dedupe_key: `birthday:${contact.id}:${format(due, "yyyy-MM-dd")}`,
        });
      }
    }

    if (contact.anniversary_month && contact.anniversary_day) {
      const due = nextOccurrence(
        contact.anniversary_month,
        contact.anniversary_day,
        now,
      );
      if (due && !isBefore(horizon, due)) {
        inserts.push({
          user_id: userId,
          type: "anniversary",
          status: "pending",
          due_at: morningOf(due).toISOString(),
          title: `${contact.display_name ?? "Someone"}'s anniversary`,
          body: `Remember ${contact.display_name ?? "them"} today.`,
          contact_id: contact.id,
          note_id: null,
          event_id: null,
          dedupe_key: `anniversary:${contact.id}:${format(due, "yyyy-MM-dd")}`,
        });
      }
    }
  }

  // Pre-event: match attendees to contacts and surface recent notes
  for (const event of eventList) {
    if (!event.starts_at) continue;
    const start = new Date(event.starts_at);
    const dueAt = new Date(start.getTime() - leadHours * 60 * 60 * 1000);
    if (isBefore(dueAt, addDays(now, -1))) continue;

    const matchedContacts = new Map<string, Contact>();
    for (const email of event.attendee_emails ?? []) {
      const match = emailToContact.get(email.toLowerCase());
      if (match) matchedContacts.set(match.id, match);
    }

    for (const contact of matchedContacts.values()) {
      const recentNotes = noteList
        .filter((n) => n.contact_id === contact.id)
        .sort(
          (a, b) =>
            new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
        )
        .slice(0, 3);

      const notesSummary =
        recentNotes.length > 0
          ? recentNotes.map((n) => `• ${n.body}`).join("\n")
          : "No notes yet — add something to remember before you meet.";

      inserts.push({
        user_id: userId,
        type: "pre_event",
        status: "pending",
        due_at: dueAt.toISOString(),
        title: `Before ${event.title ?? "your event"} with ${contact.display_name ?? "a friend"}`,
        body: notesSummary,
        contact_id: contact.id,
        note_id: recentNotes[0]?.id ?? null,
        event_id: event.id,
        dedupe_key: `pre_event:${event.id}:${contact.id}`,
      });
    }
  }

  // Refresh auto-generated pending reminders; keep dismissed/sent history.
await supabase
    .from("reminders")
    .delete()
    .eq("user_id", userId)
    .eq("status", "pending")
    .in("type", ["birthday", "anniversary", "pre_event", "note_due"]);

  if (inserts.length === 0) {
    return { created: 0 };
  }

  const { error } = await supabase.from("reminders").upsert(inserts, {
    onConflict: "user_id,dedupe_key",
    ignoreDuplicates: true,
  });

  if (error) throw error;
  return { created: inserts.length };
}

export async function materializeRemindersForAllUsers(
  supabase: SupabaseClient,
) {
  const { data: profiles, error } = await supabase.from("profiles").select("id");
  if (error) throw error;

  let total = 0;
  for (const profile of profiles ?? []) {
    const result = await materializeRemindersForUser(supabase, profile.id);
    total += result.created;
  }
  return { users: profiles?.length ?? 0, reminders: total };
}
