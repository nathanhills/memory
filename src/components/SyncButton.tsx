"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

export function SyncButton({
  label = "Sync Google",
  className = "",
}: {
  label?: string;
  className?: string;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);

  async function runSync() {
    setError(null);
    setOk(null);
    const res = await fetch("/api/sync", { method: "POST" });
    const json = await res.json();
    if (!res.ok) {
      setError(json.error ?? "Sync failed");
      return;
    }
    setOk(`Synced ${json.contacts} contacts, ${json.events} events`);
    startTransition(() => router.refresh());
  }

  return (
    <div className={className}>
      <button
        type="button"
        onClick={runSync}
        disabled={pending}
        className="inline-flex items-center justify-center rounded-lg bg-sea px-4 py-2.5 text-sm font-medium text-white transition hover:bg-sea-deep disabled:opacity-60"
      >
        {pending ? "Syncing…" : label}
      </button>
      {error && <p className="mt-2 text-sm text-coral">{error}</p>}
      {ok && <p className="mt-2 text-sm text-sea-deep">{ok}</p>}
    </div>
  );
}
