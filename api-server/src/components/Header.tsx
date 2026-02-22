import Link from "next/link";
import { getWebSession } from "@/lib/web-auth";
import AuthButtons from "./AuthButtons";

export default async function Header() {
  const session = await getWebSession();

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
          <Link
            href="/games"
            className="text-sm font-medium text-[var(--text-secondary)] transition hover:text-white"
          >
            Games
          </Link>
          <AuthButtons
            user={
              session
                ? { email: session.email, isPremium: session.isPremium }
                : null
            }
          />
        </nav>
      </div>
    </header>
  );
}
