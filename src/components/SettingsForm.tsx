"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

export function SettingsForm({
  eventReminderHours,
  emailDigestEnabled,
}: {
  eventReminderHours: number;
  emailDigestEnabled: boolean;
}) {
  const router = useRouter();
  const [hours, setHours] = useState(eventReminderHours);
  const [digest, setDigest] = useState(emailDigestEnabled);
  const [pending, startTransition] = useTransition();
  const [message, setMessage] = useState<string | null>(null);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    setMessage(null);
    const res = await fetch("/api/settings", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        event_reminder_hours: hours,
        email_digest_enabled: digest,
      }),
    });
    const json = await res.json();
    if (!res.ok) {
      setMessage(json.error ?? "Save failed");
      return;
    }
    setMessage("Saved");
    startTransition(() => router.refresh());
  }

  return (
    <form onSubmit={save} className="max-w-md space-y-5">
      <label className="block">
        <span className="mb-1 block text-sm text-ink-soft">
          Hours before calendar events to surface notes
        </span>
        <input
          type="number"
          min={1}
          max={168}
          value={hours}
          onChange={(e) => setHours(Number(e.target.value))}
          className="w-full rounded-lg border border-line bg-white/70 px-3 py-2 outline-none ring-sea/30 focus:ring-2"
        />
      </label>
      <label className="flex items-center gap-3 text-sm text-ink">
        <input
          type="checkbox"
          checked={digest}
          onChange={(e) => setDigest(e.target.checked)}
          className="size-4 accent-sea"
        />
        Email digests for upcoming reminders
      </label>
      <button
        type="submit"
        disabled={pending}
        className="rounded-lg bg-sea px-4 py-2 text-sm font-medium text-white hover:bg-sea-deep disabled:opacity-60"
      >
        {pending ? "Saving…" : "Save settings"}
      </button>
      {message && <p className="text-sm text-sea-deep">{message}</p>}
    </form>
  );
}
