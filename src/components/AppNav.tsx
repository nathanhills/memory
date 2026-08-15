import Link from "next/link";
import { signOut } from "@/app/auth/actions";

const links = [
  { href: "/home", label: "Today" },
  { href: "/people", label: "People" },
  { href: "/reminders", label: "Reminders" },
  { href: "/settings", label: "Settings" },
];

export function AppNav({ name }: { name?: string | null }) {
  return (
    <header className="sticky top-0 z-40 border-b border-line/80 bg-foam/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-3 sm:px-6">
        <Link
          href="/home"
          className="font-[family-name:var(--font-display)] text-2xl tracking-tight text-sea-deep transition hover:text-sea"
        >
          Memory
        </Link>
        <nav className="flex flex-1 items-center justify-end gap-1 sm:gap-2">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="rounded-md px-2.5 py-1.5 text-sm text-ink-soft transition hover:bg-mist hover:text-ink sm:px-3"
            >
              {link.label}
            </Link>
          ))}
          <form action={signOut} className="ml-1">
            <button
              type="submit"
              className="rounded-md px-2.5 py-1.5 text-sm text-ink-soft transition hover:bg-mist hover:text-ink"
              title={name ?? "Sign out"}
            >
              Sign out
            </button>
          </form>
        </nav>
      </div>
    </header>
  );
}
