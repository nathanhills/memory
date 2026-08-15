import type { SupabaseClient } from "@supabase/supabase-js";
import { fetchGoogleContacts } from "@/lib/google/contacts";
import { fetchUpcomingCalendarEvents } from "@/lib/google/calendar";
import { getValidGoogleAccessToken } from "@/lib/google/tokens";
import { materializeRemindersForUser } from "@/lib/reminders/engine";

export async function syncContactsAndCalendar(
  supabase: SupabaseClient,
  userId: string,
) {
  const accessToken = await getValidGoogleAccessToken(supabase, userId);

  try {
    const [contacts, events] = await Promise.all([
      fetchGoogleContacts(accessToken),
      fetchUpcomingCalendarEvents(accessToken, 90),
    ]);

    if (contacts.length > 0) {
      const rows = contacts.map((c) => ({
        ...c,
        user_id: userId,
        updated_at: new Date().toISOString(),
      }));

      const { error } = await supabase.from("contacts").upsert(rows, {
        onConflict: "user_id,google_resource_name",
      });
      if (error) throw error;
    }

    if (events.length > 0) {
      const rows = events.map((e) => ({
        ...e,
        user_id: userId,
        updated_at: new Date().toISOString(),
      }));

      const { error } = await supabase.from("calendar_events").upsert(rows, {
        onConflict: "user_id,google_event_id",
      });
      if (error) throw error;
    }

    const now = new Date().toISOString();
    const { error: syncError } = await supabase.from("sync_state").upsert({
      user_id: userId,
      contacts_synced_at: now,
      calendar_synced_at: now,
      last_error: null,
      updated_at: now,
    });
    if (syncError) throw syncError;

    await materializeRemindersForUser(supabase, userId);

    return {
      contacts: contacts.length,
      events: events.length,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : "Sync failed";
    await supabase.from("sync_state").upsert({
      user_id: userId,
      last_error: message,
      updated_at: new Date().toISOString(),
    });
    throw err;
  }
}
