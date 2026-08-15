import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { persistGoogleTokens } from "@/lib/google/tokens";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/home";

  if (code) {
    const supabase = await createClient();
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error && data.session && data.user) {
      await persistGoogleTokens(supabase, data.user.id, {
        access_token: data.session.provider_token,
        refresh_token: data.session.provider_refresh_token,
        expires_at: data.session.expires_at,
      });

      // Ensure profile row exists even if trigger missed
      await supabase.from("profiles").upsert({
        id: data.user.id,
        email: data.user.email,
        full_name:
          data.user.user_metadata?.full_name ??
          data.user.user_metadata?.name ??
          null,
        avatar_url: data.user.user_metadata?.avatar_url ?? null,
        updated_at: new Date().toISOString(),
      });

      await supabase.from("sync_state").upsert({
        user_id: data.user.id,
        updated_at: new Date().toISOString(),
      });

      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/?error=auth`);
}
