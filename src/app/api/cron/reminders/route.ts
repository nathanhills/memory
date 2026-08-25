import { NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/admin";
import { materializeRemindersForAllUsers } from "@/lib/reminders/engine";
import { sendReminderDigests } from "@/lib/reminders/email";

function authorized(request: Request) {
  const secret = process.env.CRON_SECRET;
  if (!secret) return false;
  const header = request.headers.get("authorization");
  return header === `Bearer ${secret}`;
}

export async function GET(request: Request) {
  if (!authorized(request)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const supabase = createServiceClient();
    const materialized = await materializeRemindersForAllUsers(supabase);
    const digests = await sendReminderDigests(supabase);
    return NextResponse.json({ ok: true, materialized, digests });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Cron failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
