import { addDays } from "date-fns";
import { createClient } from "@/lib/supabase/server";
import { ReminderList } from "@/components/ReminderList";
import type { ReminderWithRelations } from "@/lib/types/database";

export default async function RemindersPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data } = await supabase
    .from("reminders")
    .select(
      "*, contacts(id, display_name, photo_url), contact_notes(id, body), calendar_events(id, title, starts_at)",
    )
    .eq("user_id", user!.id)
    .neq("status", "dismissed")
    .lte("due_at", addDays(new Date(), 60).toISOString())
    .order("due_at", { ascending: true })
    .limit(50);

  const reminders = (data ?? []) as ReminderWithRelations[];

  return (
    <div>
      <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
        Reminders
      </h1>
      <p className="mt-1 mb-8 text-ink-soft">
        Notes due, birthdays, anniversaries, and pre-event context.
      </p>
      <ReminderList reminders={reminders} />
    </div>
  );
}
