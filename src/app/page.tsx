import { signInWithGoogle } from "@/app/auth/actions";

export default async function LandingPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;

  return (
    <div className="relative flex min-h-full flex-col overflow-hidden">
      <div
        aria-hidden
        className="blob-pulse pointer-events-none absolute -left-24 top-20 size-72 rounded-full bg-sea/15 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-16 bottom-10 size-80 rounded-full bg-coral/10 blur-3xl"
      />

      <div className="relative mx-auto flex w-full max-w-3xl flex-1 flex-col justify-center px-6 py-16 sm:py-24">
        <p className="animate-fade-up font-[family-name:var(--font-display)] text-5xl tracking-tight text-sea-deep sm:text-7xl">
          Memory
        </p>
        <h1 className="animate-fade-up-delay mt-6 max-w-xl font-[family-name:var(--font-display)] text-2xl leading-snug text-ink sm:text-3xl">
          Keep the people in your life close — notes, birthdays, and what to
          remember before you meet.
        </h1>
        <p className="animate-fade-up-delay-2 mt-4 max-w-lg text-lg text-ink-soft">
          Connect Google Contacts and Calendar, jot notes about friends, and get
          reminded when it matters.
        </p>

        <form action={signInWithGoogle} className="animate-fade-up-delay-2 mt-10">
          <button
            type="submit"
            className="rounded-lg bg-sea px-6 py-3 text-base font-medium text-white shadow-sm transition hover:bg-sea-deep"
          >
            Continue with Google
          </button>
        </form>

        {params.error && (
          <p className="mt-4 text-sm text-coral">
            Sign-in failed:{" "}
            {params.error === "auth" ? "please try again" : params.error}
          </p>
        )}

        <p className="mt-6">
          <a
            href="/demo"
            className="text-sm font-medium text-sea underline-offset-2 hover:underline"
          >
            Preview the app with demo data →
          </a>
        </p>

        <p className="mt-6 max-w-md text-sm text-ink-soft/80">
          We request read-only access to your contacts and calendar. Notes stay
          in your Memory account.
        </p>
      </div>
    </div>
  );
}
