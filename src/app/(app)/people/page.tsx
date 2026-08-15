import { createClient } from "@/lib/supabase/server";
import { PeopleSearch } from "@/components/PeopleSearch";
import { SyncButton } from "@/components/SyncButton";
import type { Contact } from "@/lib/types/database";

export default async function PeoplePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data } = await supabase
    .from("contacts")
    .select("*")
    .eq("user_id", user!.id)
    .order("display_name", { ascending: true });

  const contacts = (data ?? []) as Contact[];

  return (
    <div>
      <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
            People
          </h1>
          <p className="mt-1 text-ink-soft">
            Your synced contacts — open anyone to leave a note.
          </p>
        </div>
        <SyncButton label="Sync" />
      </div>

      {contacts.length === 0 ? (
        <div className="rounded-xl border border-line/80 bg-white/50 p-6">
          <p className="text-ink-soft">
            No contacts yet. Sync from Google to populate this list.
          </p>
          <SyncButton className="mt-4" label="Sync contacts & calendar" />
        </div>
      ) : (
        <PeopleSearch contacts={contacts} />
      )}
    </div>
  );
}
