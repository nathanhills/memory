import { notFound } from "next/navigation";
import { format } from "date-fns";
import {
  demoContacts,
  demoNotes,
  demoReminders,
} from "@/lib/demo/mock-data";

export default async function DemoPersonPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const person = demoContacts.find((c) => c.id === id);
  if (!person) notFound();

  const notes = demoNotes.filter((n) => n.contact_id === person.id);
  const preEvent = demoReminders.find(
    (r) => r.contact_id === person.id && r.type === "pre_event",
  );

  return (
    <div className="space-y-10">
      <header className="flex items-start gap-4">
        <span className="flex size-16 items-center justify-center rounded-full bg-mist text-lg font-medium text-sea-deep">
          {(person.display_name ?? "?")
            .split(" ")
            .map((p) => p[0])
            .slice(0, 2)
            .join("")
            .toUpperCase()}
        </span>
        <div>
          <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
            {person.display_name}
          </h1>
          <p className="text-ink-soft">{person.emails[0]}</p>
          {person.birthday_month && person.birthday_day && (
            <p className="mt-1 text-sm text-sea">
              Birthday {person.birthday_month}/{person.birthday_day}
            </p>
          )}
        </div>
      </header>

      {preEvent && (
        <section className="rounded-xl border border-sea/20 bg-mist/40 p-4">
          <p className="text-xs uppercase tracking-wide text-sea">Before event</p>
          <p className="mt-1 font-medium">{preEvent.title}</p>
          <p className="mt-2 whitespace-pre-wrap text-sm text-ink-soft">
            {preEvent.body}
          </p>
        </section>
      )}

      <section>
        <h2 className="mb-4 font-[family-name:var(--font-display)] text-xl">
          Notes
        </h2>
        <ul className="space-y-4">
          {notes.map((note) => (
            <li
              key={note.id}
              className="border-b border-line/70 pb-4 last:border-0"
            >
              <p className="whitespace-pre-wrap text-ink">{note.body}</p>
              <div className="mt-2 flex gap-3 text-xs text-ink-soft">
                <span>{format(new Date(note.created_at), "MMM d, yyyy")}</span>
                {note.remind_at && (
                  <span className="text-coral">
                    Remind {format(new Date(note.remind_at), "MMM d, yyyy · p")}
                  </span>
                )}
              </div>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}
