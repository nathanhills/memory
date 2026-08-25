import { google } from "googleapis";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Profile } from "@/lib/types/database";

const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";

type TokenBundle = {
  accessToken: string;
  refreshToken: string | null;
  expiresAt: Date | null;
};

export async function persistGoogleTokens(
  supabase: SupabaseClient,
  userId: string,
  tokens: {
    access_token?: string | null;
    refresh_token?: string | null;
    expires_at?: number | null;
    expires_in?: number | null;
  },
) {
  const expiresAt =
    tokens.expires_at != null
      ? new Date(tokens.expires_at * 1000).toISOString()
      : tokens.expires_in != null
        ? new Date(Date.now() + tokens.expires_in * 1000).toISOString()
        : null;

  const patch: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };

  if (tokens.access_token) {
    patch.google_access_token = tokens.access_token;
  }
  if (tokens.refresh_token) {
    patch.google_refresh_token = tokens.refresh_token;
  }
  if (expiresAt) {
    patch.google_token_expires_at = expiresAt;
  }

  await supabase.from("profiles").upsert({ id: userId, ...patch });
}

async function refreshAccessToken(refreshToken: string): Promise<TokenBundle> {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error(
      "GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are required to refresh Google tokens",
    );
  }

  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    refresh_token: refreshToken,
    grant_type: "refresh_token",
  });

  const res = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to refresh Google token: ${text}`);
  }

  const json = (await res.json()) as {
    access_token: string;
    expires_in: number;
    refresh_token?: string;
  };

  return {
    accessToken: json.access_token,
    refreshToken: json.refresh_token ?? refreshToken,
    expiresAt: new Date(Date.now() + json.expires_in * 1000),
  };
}

export async function getValidGoogleAccessToken(
  supabase: SupabaseClient,
  userId: string,
): Promise<string> {
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  const p = profile as Profile | null;
  if (!p) {
    throw new Error("Profile not found. Sign in again.");
  }

  const expiresAt = p.google_token_expires_at
    ? new Date(p.google_token_expires_at).getTime()
    : 0;
  const stillValid =
    p.google_access_token && expiresAt > Date.now() + 60_000;

  if (stillValid && p.google_access_token) {
    return p.google_access_token;
  }

  if (!p.google_refresh_token) {
    throw new Error(
      "Google access expired. Sign out and sign in again to reconnect Contacts and Calendar.",
    );
  }

  const refreshed = await refreshAccessToken(p.google_refresh_token);
  await persistGoogleTokens(supabase, userId, {
    access_token: refreshed.accessToken,
    refresh_token: refreshed.refreshToken,
    expires_in: refreshed.expiresAt
      ? Math.floor((refreshed.expiresAt.getTime() - Date.now()) / 1000)
      : null,
  });

  return refreshed.accessToken;
}

export function googleClient(accessToken: string) {
  const auth = new google.auth.OAuth2();
  auth.setCredentials({ access_token: accessToken });
  return auth;
}
