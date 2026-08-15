"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { format } from "date-fns";
import type { ReminderWithRelations } from "@/lib/types/database";

const typeLabel: Record<string, string> = {
  note_due: "Note",
  birthday: "Birthday",
  anniversary: "Anniversary",
  pre_event: "Before event",
};

export function ReminderList({
  reminders,
}: {
  reminders: ReminderWithRelations[];
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  async function dismiss(id: string) {
    await fetch("/api/reminders", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, status: "dismissed" }),
    });
    startTransition(() => router.refresh());
  }

  if (reminders.length === 0) {
    return (
      <p className="text-ink-soft">
        Nothing queued right now. Sync contacts and add notes to grow this list.
      </p>
    );
  }

  return (
    <ul className="space-y-5">
      {reminders.map((r) => (
        <li key={r.id} className="animate-fade-up border-b border-line/60 pb-5">
          <div className="mb-1 flex flex-wrap items-baseline gap-2">
            <span className="text-xs font-medium uppercase tracking-wide text-sea">
              {typeLabel[r.type] ?? r.type}
            </span>
            <time className="text-xs text-ink-soft">
              {format(new Date(r.due_at), "EEE, MMM d · p")}
            </time>
          </div>
          <h3 className="font-[family-name:var(--font-display)] text-xl text-ink">
            {r.title}
          </h3>
          {r.body && (
            <p className="mt-2 whitespace-pre-wrap text-sm leading-relaxed text-ink-soft">
              {r.body}
            </p>
          )}
          {r.status === "pending" && (
            <button
              type="button"
              disabled={pending}
              onClick={() => dismiss(r.id)}
              className="mt-3 text-sm text-ink-soft underline-offset-2 hover:text-sea hover:underline"
            >
              Dismiss
            </button>
          )}
        </li>
      ))}
    </ul>
  );
}
