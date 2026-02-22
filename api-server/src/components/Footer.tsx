import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-white/[0.06] bg-black">
      <div className="mx-auto max-w-3xl px-5 py-10">
        <div className="flex flex-col items-center gap-6 text-center">
          <div className="flex items-center gap-2">
            <span className="text-xl">💩</span>
            <span className="text-lg font-black text-white">TheDailyPoop</span>
          </div>

          <p className="max-w-md text-sm text-[var(--text-secondary)]">
            25 stories a day. Zero boring ones. News that actually makes you
            laugh.
          </p>

          <a
            href="https://apps.apple.com/app/thedailypoop/id6738030377"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full bg-[var(--accent)] px-6 py-2 text-sm font-bold text-black transition hover:brightness-110"
          >
            Download Free on iPhone
          </a>

          <div className="flex gap-6 text-xs text-[var(--text-tertiary)]">
            <Link href="/today" className="hover:text-white transition">
              Today
            </Link>
            <Link href="/archive" className="hover:text-white transition">
              Archive
            </Link>
            <a
              href="https://thedailypoop.com/legal/privacy"
              className="hover:text-white transition"
            >
              Privacy
            </a>
            <a
              href="https://thedailypoop.com/legal/terms"
              className="hover:text-white transition"
            >
              Terms
            </a>
          </div>

          <p className="text-xs text-[var(--text-tertiary)]">
            &copy; {new Date().getFullYear()} TheDailyPoop. All rights
            reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
