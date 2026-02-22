import Link from "next/link";

export default function Header() {
  return (
    <header className="sticky top-0 z-50 border-b border-white/[0.06] bg-black/80 backdrop-blur-xl">
      <div className="mx-auto flex max-w-3xl items-center justify-between px-5 py-3">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-xl">💩</span>
          <span className="text-lg font-black tracking-tight text-white">
            TheDailyPoop
          </span>
        </Link>

        <nav className="flex items-center gap-4">
          <Link
            href="/today"
            className="text-sm font-medium text-[var(--text-secondary)] transition hover:text-white"
          >
            Today
          </Link>
          <Link
            href="/archive"
            className="text-sm font-medium text-[var(--text-secondary)] transition hover:text-white"
          >
            Archive
          </Link>
          <a
            href="https://apps.apple.com/app/thedailypoop/id6738030377"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full bg-[var(--accent)] px-4 py-1.5 text-xs font-bold text-black transition hover:brightness-110"
          >
            Get the App
          </a>
        </nav>
      </div>
    </header>
  );
}
