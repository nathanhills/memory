import { createClient } from "@/lib/supabase/server";
import { SettingsForm } from "@/components/SettingsForm";
import { SyncButton } from "@/components/SyncButton";
import type { Profile, SyncState } from "@/lib/types/database";
import { format } from "date-fns";

export default async function SettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [{ data: profile }, { data: sync }] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", user!.id).maybeSingle(),
    supabase.from("sync_state").select("*").eq("user_id", user!.id).maybeSingle(),
  ]);

  const p = profile as Profile | null;
  const syncState = sync as SyncState | null;

  return (
    <div className="space-y-10">
      <div>
        <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
          Settings
        </h1>
        <p className="mt-1 text-ink-soft">
          Sync schedule preferences and Google data.
        </p>
      </div>

      <section>
        <h2 className="mb-3 font-[family-name:var(--font-display)] text-xl">
          Google sync
        </h2>
        <SyncButton label="Sync contacts & calendar now" />
        {syncState?.contacts_synced_at && (
          <p className="mt-2 text-sm text-ink-soft">
            Contacts: {format(new Date(syncState.contacts_synced_at), "PPp")}
          </p>
        )}
        {syncState?.calendar_synced_at && (
          <p className="text-sm text-ink-soft">
            Calendar: {format(new Date(syncState.calendar_synced_at), "PPp")}
          </p>
        )}
        {syncState?.last_error && (
          <p className="mt-2 text-sm text-coral">{syncState.last_error}</p>
        )}
      </section>

      <section>
        <h2 className="mb-3 font-[family-name:var(--font-display)] text-xl">
          Reminders
        </h2>
        <SettingsForm
          eventReminderHours={p?.event_reminder_hours ?? 24}
          emailDigestEnabled={p?.email_digest_enabled ?? true}
        />
      </section>
    </div>
  );
}
