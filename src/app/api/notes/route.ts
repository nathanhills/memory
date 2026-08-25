import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { materializeRemindersForUser } from "@/lib/reminders/engine";

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await request.json()) as {
    contact_id: string;
    body: string;
    tags?: string[];
    remind_at?: string | null;
  };

  if (!body.contact_id || !body.body?.trim()) {
    return NextResponse.json(
      { error: "contact_id and body are required" },
      { status: 400 },
    );
  }

  const { data, error } = await supabase
    .from("contact_notes")
    .insert({
      user_id: user.id,
      contact_id: body.contact_id,
      body: body.body.trim(),
      tags: body.tags ?? [],
      remind_at: body.remind_at || null,
    })
    .select("*")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  await materializeRemindersForUser(supabase, user.id);
  return NextResponse.json({ note: data });
}

export async function PATCH(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await request.json()) as {
    id: string;
    body?: string;
    tags?: string[];
    remind_at?: string | null;
  };

  if (!body.id) {
    return NextResponse.json({ error: "id is required" }, { status: 400 });
  }

  const patch: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };
  if (body.body !== undefined) patch.body = body.body.trim();
  if (body.tags !== undefined) patch.tags = body.tags;
  if (body.remind_at !== undefined) patch.remind_at = body.remind_at || null;

  const { data, error } = await supabase
    .from("contact_notes")
    .update(patch)
    .eq("id", body.id)
    .eq("user_id", user.id)
    .select("*")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  await materializeRemindersForUser(supabase, user.id);
  return NextResponse.json({ note: data });
}

export async function DELETE(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id");
  if (!id) {
    return NextResponse.json({ error: "id is required" }, { status: 400 });
  }

  const { error } = await supabase
    .from("contact_notes")
    .delete()
    .eq("id", id)
    .eq("user_id", user.id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
