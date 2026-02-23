import Link from "next/link";
import Image from "next/image";
import { getWebSession } from "@/lib/web-auth";
import AuthButtons from "./AuthButtons";

export default async function Header() {
  const session = await getWebSession();

  return (
    <header className="sticky top-0 z-50 border-b border-white/[0.06] bg-black/80 backdrop-blur-xl">
      <div className="flex items-center justify-between px-5 py-3 sm:px-8 lg:px-12">
        <Link href="/" className="pressable flex items-center gap-2">
          <Image
            src="/logo.png"
            alt="TheDailyPoop"
            width={30}
            height={30}
            className="drop-shadow-md"
          />
          <span className="text-[15px] font-black tracking-tight text-white">
            TheDailyPoop
          </span>
        </Link>

        <nav className="flex items-center gap-0.5">
          <Link
            href="/today"
            className="rounded-lg px-3 py-1.5 text-[13px] font-medium text-zinc-400 transition hover:bg-white/[0.05] hover:text-white"
          >
            Today
          </Link>
          <Link
            href="/archive"
            className="rounded-lg px-3 py-1.5 text-[13px] font-medium text-zinc-400 transition hover:bg-white/[0.05] hover:text-white"
          >
            Archive
          </Link>
          <Link
            href="/games"
            className="rounded-lg px-3 py-1.5 text-[13px] font-medium text-zinc-400 transition hover:bg-white/[0.05] hover:text-white"
          >
            Games
          </Link>
          {!session?.isPremium && (
            <Link
              href="/pro"
              className="rounded-lg px-3 py-1.5 text-[13px] font-bold text-[var(--accent)] transition hover:bg-[var(--accent)]/10"
            >
              Pro
            </Link>
          )}
          <div className="ml-2 border-l border-white/[0.08] pl-3">
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
