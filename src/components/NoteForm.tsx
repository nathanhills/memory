"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

export function NoteForm({ contactId }: { contactId: string }) {
  const router = useRouter();
  const [body, setBody] = useState("");
  const [remindAt, setRemindAt] = useState("");
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const res = await fetch("/api/notes", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contact_id: contactId,
        body,
        remind_at: remindAt ? new Date(remindAt).toISOString() : null,
      }),
    });
    const json = await res.json();
    if (!res.ok) {
      setError(json.error ?? "Could not save note");
      return;
    }
    setBody("");
    setRemindAt("");
    startTransition(() => router.refresh());
  }

  return (
    <form onSubmit={onSubmit} className="space-y-3">
      <label className="block">
        <span className="mb-1 block text-sm text-ink-soft">New note</span>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          required
          rows={3}
          placeholder="Something you want to remember…"
          className="w-full resize-y rounded-lg border border-line bg-white/70 px-3 py-2 text-ink outline-none ring-sea/30 focus:ring-2"
        />
      </label>
      <label className="block max-w-xs">
        <span className="mb-1 block text-sm text-ink-soft">
          Remind me on (optional)
        </span>
        <input
          type="datetime-local"
          value={remindAt}
          onChange={(e) => setRemindAt(e.target.value)}
          className="w-full rounded-lg border border-line bg-white/70 px-3 py-2 text-ink outline-none ring-sea/30 focus:ring-2"
        />
      </label>
      {error && <p className="text-sm text-coral">{error}</p>}
      <button
        type="submit"
        disabled={pending || !body.trim()}
        className="rounded-lg bg-sea px-4 py-2 text-sm font-medium text-white transition hover:bg-sea-deep disabled:opacity-60"
      >
        {pending ? "Saving…" : "Save note"}
      </button>
    </form>
  );
}
