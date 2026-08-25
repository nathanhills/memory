import Link from "next/link";

const links = [
  { href: "/demo", label: "Today" },
  { href: "/demo/people", label: "People" },
  { href: "/demo/reminders", label: "Reminders" },
];

export function DemoNav() {
  return (
    <header className="sticky top-0 z-40 border-b border-line/80 bg-foam/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-3 sm:px-6">
        <Link
          href="/demo"
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
          <Link
            href="/"
            className="ml-1 rounded-md px-2.5 py-1.5 text-sm text-coral transition hover:bg-mist sm:px-3"
          >
            Sign in
          </Link>
        </nav>
      </div>
      <div className="border-t border-line/50 bg-sand/30 px-4 py-1.5 text-center text-xs text-ink-soft">
        Demo preview — sample data, no Google account required
      </div>
    </header>
  );
}
