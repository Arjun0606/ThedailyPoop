import Link from "next/link";
import Image from "next/image";
import { getWebSession } from "@/lib/web-auth";
import AuthButtons from "./AuthButtons";

export default async function Header() {
  const session = await getWebSession();

  return (
    <header className="sticky top-0 z-50 bg-black/90 backdrop-blur-xl">
      <div className="flex items-center justify-between px-5 py-4 sm:px-8 lg:px-12">
        <Link href="/" className="pressable flex items-center gap-2.5">
          <Image
            src="/logo.png"
            alt="TheDailyPoop"
            width={34}
            height={34}
            className="drop-shadow-md"
          />
          <span className="text-lg font-black tracking-tight text-white">
            TheDailyPoop
          </span>
        </Link>

        <nav className="flex items-center">
          <Link
            href="/today"
            className="px-4 py-2 text-sm font-medium text-zinc-400 transition hover:text-white"
          >
            Today
          </Link>
          <Link
            href="/archive"
            className="px-4 py-2 text-sm font-medium text-zinc-400 transition hover:text-white"
          >
            Archive
          </Link>
          <Link
            href="/games"
            className="px-4 py-2 text-sm font-medium text-zinc-400 transition hover:text-white"
          >
            Games
          </Link>
          {!session?.isPremium && (
            <Link
              href="/pro"
              className="px-4 py-2 text-sm font-bold text-[var(--accent)] transition hover:text-[var(--accent-hover)]"
            >
              Pro
            </Link>
          )}
          <div className="ml-4 pl-4 border-l border-zinc-800">
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
      <div className="h-px bg-gradient-to-r from-transparent via-zinc-800 to-transparent" />
    </header>
  );
}
