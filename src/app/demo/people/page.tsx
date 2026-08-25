import Link from "next/link";
import { demoContacts } from "@/lib/demo/mock-data";

export default function DemoPeoplePage() {
  return (
    <div>
      <div className="mb-8">
        <h1 className="font-[family-name:var(--font-display)] text-3xl text-ink">
          People
        </h1>
        <p className="mt-1 text-ink-soft">
          Your synced contacts — open anyone to leave a note.
        </p>
      </div>

      <ul className="divide-y divide-line/70">
        {demoContacts.map((c) => (
          <li key={c.id}>
            <Link
              href={`/demo/people/${c.id}`}
              className="flex items-center gap-3 py-3 transition hover:bg-mist/50"
            >
              <span className="flex size-10 items-center justify-center rounded-full bg-mist text-sm font-medium text-sea-deep">
                {(c.display_name ?? "?")
                  .split(" ")
                  .map((p) => p[0])
                  .slice(0, 2)
                  .join("")
                  .toUpperCase()}
              </span>
              <span>
                <span className="block font-medium text-ink">
                  {c.display_name}
                </span>
                <span className="text-sm text-ink-soft">{c.emails[0]}</span>
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
