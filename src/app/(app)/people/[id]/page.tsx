import { notFound } from "next/navigation";
import { format } from "date-fns";
import { createClient } from "@/lib/supabase/server";
import { NoteForm } from "@/components/NoteForm";
import { NotesList } from "@/components/NotesList";
import type {
  CalendarEvent,
  Contact,
  ContactNote,
} from "@/lib/types/database";

export default async function PersonPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: contact } = await supabase
    .from("contacts")
    .select("*")
    .eq("id", id)
    .eq("user_id", user!.id)
    .maybeSingle();

  if (!contact) notFound();
  const person = contact as Contact;

  const [{ data: notes }, { data: events }] = await Promise.all([
    supabase
      .from("contact_notes")
      .select("*")
      .eq("contact_id", person.id)
      .eq("user_id", user!.id)
      .order("created_at", { ascending: false }),
    supabase
      .from("calendar_events")
      .select("*")
      .eq("user_id", user!.id)
      .gte("starts_at", new Date().toISOString())
      .order("starts_at", { ascending: true })
      .limit(50),
  ]);

  const noteList = (notes ?? []) as ContactNote[];
  const emailSet = new Set((person.emails ?? []).map((e) => e.toLowerCase()));
  const sharedEvents = ((events ?? []) as CalendarEvent[]).filter((e) =>
    (e.attendee_emails ?? []).some((a) => emailSet.has(a.toLowerCase())),
  );

  return (
    <div className="space-y-10">
      <header className="flex items-start gap-4">
        {person.photo_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={person.photo_url}
            alt=""
            className="size-16 rounded-full object-cover"
            referrerPolicy="no-referrer"
          />
        ) : (
          <span className="flex size-16 items-center justify-center rounded-full bg-mist text-lg font-medium text-sea-deep">
            {(person.display_name ?? "?")
              .split(" ")
              .map((p) => p[0])
              .slice(0, 2)
              .join("")
              .toUpperCase()}
          </span>
        )}
        <div>
          <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
            {person.display_name ?? "Unnamed"}
          </h1>
          {person.emails?.[0] && (
            <p className="text-ink-soft">{person.emails[0]}</p>
          )}
          {(person.birthday_month && person.birthday_day) && (
            <p className="mt-1 text-sm text-sea">
              Birthday {person.birthday_month}/{person.birthday_day}
              {person.birthday_year ? `/${person.birthday_year}` : ""}
            </p>
          )}
        </div>
      </header>

      <section>
        <h2 className="mb-4 font-[family-name:var(--font-display)] text-xl">
          Notes
        </h2>
        <div className="mb-8">
          <NoteForm contactId={person.id} />
        </div>
        <NotesList notes={noteList} />
      </section>

      <section>
        <h2 className="mb-4 font-[family-name:var(--font-display)] text-xl">
          Upcoming together
        </h2>
        {sharedEvents.length === 0 ? (
          <p className="text-sm text-ink-soft">
            No upcoming calendar events with matching attendees.
          </p>
        ) : (
          <ul className="space-y-3">
            {sharedEvents.map((e) => (
              <li key={e.id} className="border-b border-line/50 py-2">
                <p className="font-medium">{e.title ?? "Untitled event"}</p>
                {e.starts_at && (
                  <p className="text-sm text-ink-soft">
                    {format(new Date(e.starts_at), "PPp")}
                  </p>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
