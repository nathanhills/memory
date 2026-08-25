"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { Contact } from "@/lib/types/database";

export function PeopleSearch({ contacts }: { contacts: Contact[] }) {
  const [q, setQ] = useState("");

  const filtered = useMemo(() => {
    const query = q.trim().toLowerCase();
    if (!query) return contacts;
    return contacts.filter((c) => {
      const hay = [
        c.display_name,
        c.given_name,
        c.family_name,
        ...(c.emails ?? []),
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      return hay.includes(query);
    });
  }, [contacts, q]);

  return (
    <div>
      <label className="mb-4 block">
        <span className="sr-only">Search people</span>
        <input
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search by name or email"
          className="w-full rounded-lg border border-line bg-white/70 px-4 py-2.5 outline-none ring-sea/30 focus:ring-2"
        />
      </label>

      {filtered.length === 0 ? (
        <p className="text-ink-soft">No people match that search.</p>
      ) : (
        <ul className="divide-y divide-line/70">
          {filtered.map((c) => (
            <li key={c.id}>
              <Link
                href={`/people/${c.id}`}
                className="flex items-center gap-3 py-3 transition hover:bg-mist/50"
              >
                {c.photo_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={c.photo_url}
                    alt=""
                    className="size-10 rounded-full object-cover"
                    referrerPolicy="no-referrer"
                  />
                ) : (
                  <span className="flex size-10 items-center justify-center rounded-full bg-mist text-sm font-medium text-sea-deep">
                    {(c.display_name ?? "?")
                      .split(" ")
                      .map((p) => p[0])
                      .slice(0, 2)
                      .join("")
                      .toUpperCase()}
                  </span>
                )}
                <span>
                  <span className="block font-medium text-ink">
                    {c.display_name ?? "Unnamed"}
                  </span>
                  {c.emails?.[0] && (
                    <span className="text-sm text-ink-soft">{c.emails[0]}</span>
                  )}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
