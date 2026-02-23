import Link from "next/link";
import Image from "next/image";

export default function Footer() {
  return (
    <footer className="border-t border-[var(--glass-border)] bg-black">
      <div className="mx-auto max-w-6xl px-6 py-12">
        <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-start sm:justify-between">
          {/* Brand */}
          <div className="flex flex-col items-center sm:items-start">
            <div className="flex items-center gap-2.5">
              <Image
                src="/logo.png"
                alt="TheDailyPoop"
                width={32}
                height={32}
              />
              <span className="text-lg font-black text-white">
                TheDailyPoop
              </span>
            </div>
            <p className="mt-2 max-w-xs text-sm text-[var(--text-secondary)] sm:text-left text-center">
              25 stories a day. Zero boring ones. News that actually makes you
              laugh.
            </p>
          </div>

          {/* Links */}
          <div className="flex gap-8">
            <div className="flex flex-col gap-2">
              <span className="text-[10px] font-bold uppercase tracking-[0.5px] text-[var(--text-tertiary)]">
                Read
              </span>
              <Link
                href="/today"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Today
              </Link>
              <Link
                href="/archive"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Archive
              </Link>
              <Link
                href="/games"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Games
              </Link>
            </div>
            <div className="flex flex-col gap-2">
              <span className="text-[10px] font-bold uppercase tracking-[0.5px] text-[var(--text-tertiary)]">
                App
              </span>
              <a
                href="https://apps.apple.com/app/thedailypoop/id6738030377"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                iPhone
              </a>
              <Link
                href="/legal/privacy"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Privacy
              </Link>
              <Link
                href="/legal/terms"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Terms
              </Link>
              <Link
                href="/advertise"
                className="text-sm text-[var(--text-secondary)] hover:text-white transition"
              >
                Advertise
              </Link>
            </div>
          </div>
        </div>

        <div className="mt-8 border-t border-white/[0.06] pt-6 text-center">
          <p className="text-xs text-[var(--text-tertiary)]">
            &copy; {new Date().getFullYear()} TheDailyPoop. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
