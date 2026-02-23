import Link from "next/link";
import Image from "next/image";
import { getWebSession } from "@/lib/web-auth";
import AuthButtons from "./AuthButtons";

export default async function Header() {
  const session = await getWebSession();

  return (
    <header className="sticky top-0 z-50 border-b border-[var(--glass-border)] bg-black/70 backdrop-blur-2xl">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-3">
        <Link href="/" className="pressable flex items-center gap-2.5">
          <Image
            src="/logo.png"
            alt="TheDailyPoop"
            width={36}
            height={36}
            className="drop-shadow-md"
          />
          <span className="text-lg font-black tracking-tight text-white">
            TheDailyPoop
          </span>
        </Link>

        <nav className="flex items-center gap-1">
          <Link
            href="/today"
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-[var(--text-secondary)] transition hover:bg-white/[0.06] hover:text-white"
          >
            Today
          </Link>
          <Link
            href="/archive"
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-[var(--text-secondary)] transition hover:bg-white/[0.06] hover:text-white"
          >
            Archive
          </Link>
          <Link
            href="/games"
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-[var(--text-secondary)] transition hover:bg-white/[0.06] hover:text-white"
          >
            Games
          </Link>
          {!session?.isPremium && (
            <Link
              href="/pro"
              className="rounded-lg px-3 py-1.5 text-sm font-bold text-[var(--accent)] transition hover:bg-[var(--accent)]/10"
            >
              Pro
            </Link>
          )}
          <div className="ml-3 border-l border-white/[0.08] pl-3">
            <AuthButtons
              user={
                session
                  ? { email: session.email, isPremium: session.isPremium }
                  : null
              }
            />
          </div>
        </nav>
      </div>
    </header>
  );
}
