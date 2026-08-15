import { Resend } from "resend";
import type { SupabaseClient } from "@supabase/supabase-js";
import { addHours, format } from "date-fns";
import type { Profile, Reminder } from "@/lib/types/database";

export async function sendReminderDigests(supabase: SupabaseClient) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    return { sent: 0, skipped: "RESEND_API_KEY not configured" as const };
  }

  const resend = new Resend(apiKey);
  const from =
    process.env.RESEND_FROM_EMAIL ?? "Memory <onboarding@resend.dev>";
  const windowEnd = addHours(new Date(), 24).toISOString();
  const now = new Date().toISOString();

  const { data: profiles, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("email_digest_enabled", true);

  if (error) throw error;

  let sent = 0;

  for (const profile of (profiles ?? []) as Profile[]) {
    if (!profile.email) continue;

    const { data: reminders } = await supabase
      .from("reminders")
      .select("*")
      .eq("user_id", profile.id)
      .eq("status", "pending")
      .gte("due_at", now)
      .lte("due_at", windowEnd)
      .order("due_at", { ascending: true });

    const list = (reminders ?? []) as Reminder[];
    if (list.length === 0) continue;

    const lines = list
      .map(
        (r) =>
          `• [${r.type}] ${r.title} — ${format(new Date(r.due_at), "PPp")}${
            r.body ? `\n  ${r.body}` : ""
          }`,
      )
      .join("\n\n");

    await resend.emails.send({
      from,
      to: profile.email,
      subject: `Memory: ${list.length} reminder${list.length === 1 ? "" : "s"} coming up`,
      text: `Here's what to remember in the next 24 hours:\n\n${lines}\n\n— Memory`,
    });

    const ids = list.map((r) => r.id);
    await supabase
      .from("reminders")
      .update({ status: "sent" })
      .in("id", ids);

    sent += 1;
  }

  return { sent };
}
