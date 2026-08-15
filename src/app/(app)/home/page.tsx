import Link from "next/link";
import { format, isBefore, addDays } from "date-fns";
import { createClient } from "@/lib/supabase/server";
import { SyncButton } from "@/components/SyncButton";
import type { Contact, Reminder, SyncState } from "@/lib/types/database";

export default async function HomePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const now = new Date();
  const [{ data: reminders }, { data: contacts }, { data: sync }] =
    await Promise.all([
      supabase
        .from("reminders")
        .select("*")
        .eq("user_id", user!.id)
        .eq("status", "pending")
        .lte("due_at", addDays(now, 7).toISOString())
        .order("due_at", { ascending: true })
        .limit(8),
      supabase
        .from("contacts")
        .select("id")
        .eq("user_id", user!.id)
        .limit(1),
      supabase
        .from("sync_state")
        .select("*")
        .eq("user_id", user!.id)
        .maybeSingle(),
    ]);

  const list = (reminders ?? []) as Reminder[];
  const hasContacts = ((contacts ?? []) as Pick<Contact, "id">[]).length > 0;
  const syncState = sync as SyncState | null;
  const today = list.filter((r) => isBefore(new Date(r.due_at), addDays(now, 1)));

  return (
    <div>
      <section className="animate-fade-up">
        <p className="font-[family-name:var(--font-display)] text-4xl text-sea-deep sm:text-5xl">
          Memory
        </p>
        <h1 className="mt-3 font-[family-name:var(--font-display)] text-2xl text-ink sm:text-3xl">
          Who to remember today
        </h1>
        <p className="mt-2 max-w-lg text-ink-soft">
          Birthdays, notes coming due, and friends you&apos;ll see soon.
        </p>
      </section>

      {!hasContacts && (
        <section className="animate-fade-up-delay mt-10 rounded-xl border border-line/80 bg-white/50 p-6">
          <h2 className="font-[family-name:var(--font-display)] text-xl">
            Connect your people
          </h2>
          <p className="mt-2 text-sm text-ink-soft">
            Sync Google Contacts and the next 90 days of Calendar to get started.
          </p>
          <SyncButton className="mt-4" label="Sync contacts & calendar" />
        </section>
      )}

      {hasContacts && (
        <>
          <section className="animate-fade-up-delay mt-10">
            <div className="mb-4 flex items-end justify-between gap-4">
              <h2 className="font-[family-name:var(--font-display)] text-xl">
                Coming up
              </h2>
              <Link
                href="/reminders"
                className="text-sm text-sea hover:underline"
              >
                All reminders
              </Link>
            </div>
            {list.length === 0 ? (
              <p className="text-ink-soft">
                No reminders in the next week. Add a note with a remind date, or
                wait for birthdays and meetings.
              </p>
            ) : (
              <ul className="space-y-3">
                {list.map((r) => (
                  <li key={r.id} className="border-b border-line/50 py-3">
                    <p className="text-xs uppercase tracking-wide text-sea">
                      {r.type.replace("_", " ")}
                      {today.some((t) => t.id === r.id) ? " · today" : ""}
                    </p>
                    <p className="font-medium text-ink">{r.title}</p>
                    <p className="text-sm text-ink-soft">
                      {format(new Date(r.due_at), "EEE, MMM d · p")}
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section className="animate-fade-up-delay-2 mt-10 flex flex-wrap items-center gap-4">
            <Link
              href="/people"
              className="rounded-lg bg-sea px-4 py-2.5 text-sm font-medium text-white hover:bg-sea-deep"
            >
              Browse people
            </Link>
            <SyncButton label="Re-sync Google" />
            {syncState?.contacts_synced_at && (
              <p className="w-full text-xs text-ink-soft">
                Last synced{" "}
                {format(new Date(syncState.contacts_synced_at), "PPp")}
              </p>
            )}
            {syncState?.last_error && (
              <p className="w-full text-sm text-coral">{syncState.last_error}</p>
            )}
          </section>
        </>
      )}
    </div>
  );
}
