import Link from "next/link";
import { format, isBefore, addDays } from "date-fns";
import { demoReminders } from "@/lib/demo/mock-data";

export default function DemoHomePage() {
  const now = new Date();
  const list = demoReminders.slice(0, 4);
  const today = list.filter((r) =>
    isBefore(new Date(r.due_at), addDays(now, 1)),
  );

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

      <section className="animate-fade-up-delay mt-10">
        <div className="mb-4 flex items-end justify-between gap-4">
          <h2 className="font-[family-name:var(--font-display)] text-xl">
            Coming up
          </h2>
          <Link
            href="/demo/reminders"
            className="text-sm text-sea hover:underline"
          >
            All reminders
          </Link>
        </div>
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
      </section>

      <section className="animate-fade-up-delay-2 mt-10 flex flex-wrap items-center gap-4">
        <Link
          href="/demo/people"
          className="rounded-lg bg-sea px-4 py-2.5 text-sm font-medium text-white hover:bg-sea-deep"
        >
          Browse people
        </Link>
        <p className="w-full text-xs text-ink-soft">
          Last synced {format(now, "PPp")} (demo)
        </p>
      </section>
    </div>
  );
}
