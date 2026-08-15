"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import type { ContactNote } from "@/lib/types/database";
import { format } from "date-fns";

export function NotesList({ notes }: { notes: ContactNote[] }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  async function remove(id: string) {
    await fetch(`/api/notes?id=${id}`, { method: "DELETE" });
    startTransition(() => router.refresh());
  }

  if (notes.length === 0) {
    return (
      <p className="text-sm text-ink-soft">
        No notes yet. Capture something worth remembering.
      </p>
    );
  }

  return (
    <ul className="space-y-4">
      {notes.map((note) => (
        <li
          key={note.id}
          className="border-b border-line/70 pb-4 last:border-0 last:pb-0"
        >
          <p className="whitespace-pre-wrap text-ink">{note.body}</p>
          <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-ink-soft">
            <span>{format(new Date(note.created_at), "MMM d, yyyy")}</span>
            {note.remind_at && (
              <span className="text-coral">
                Remind {format(new Date(note.remind_at), "MMM d, yyyy · p")}
              </span>
            )}
            <button
              type="button"
              disabled={pending}
              onClick={() => remove(note.id)}
              className="text-ink-soft underline-offset-2 hover:text-coral hover:underline"
            >
              Delete
            </button>
          </div>
        </li>
      ))}
    </ul>
  );
}
