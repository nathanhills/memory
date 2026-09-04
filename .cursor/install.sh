#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the Memory web app.
set -euo pipefail

cd "$(dirname "$0")/.."

npm install

# Ensure a local env file exists so `next dev` can boot. These are
# well-formed placeholders; replace with real Supabase + Google OAuth
# credentials (via secrets or a local .env.local) to enable sign-in and sync.
if [ ! -f .env.local ]; then
  cat > .env.local <<'EOF'
NEXT_PUBLIC_SUPABASE_URL=https://placeholder-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder-anon-key.placeholder-signature
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder-service-role.placeholder-signature
NEXT_PUBLIC_APP_URL=http://localhost:3000
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
CRON_SECRET=local-dev-cron-secret
RESEND_API_KEY=
RESEND_FROM_EMAIL=Memory <onboarding@resend.dev>
EOF
  echo "Created .env.local with development placeholders."
fi
