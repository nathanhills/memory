import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function PATCH(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await request.json()) as {
    event_reminder_hours?: number;
    email_digest_enabled?: boolean;
  };

  const patch: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };

  if (typeof body.event_reminder_hours === "number") {
    patch.event_reminder_hours = Math.min(
      168,
      Math.max(1, Math.round(body.event_reminder_hours)),
    );
  }
  if (typeof body.email_digest_enabled === "boolean") {
    patch.email_digest_enabled = body.email_digest_enabled;
  }

  const { data, error } = await supabase
    .from("profiles")
    .update(patch)
    .eq("id", user.id)
    .select(
      "id, email, full_name, event_reminder_hours, email_digest_enabled",
    )
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ profile: data });
}
