import Link from "next/link";
import Image from "next/image";

export default function Footer() {
  return (
    <footer className="border-t border-white/[0.06] bg-black">
      <div className="px-5 py-12 sm:px-8 lg:px-12">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-6 sm:flex-row sm:items-start sm:justify-between">
          {/* Brand */}
          <div className="flex flex-col items-center sm:items-start">
            <div className="flex items-center gap-2">
              <Image
                src="/logo.png"
                alt="TheDailyPoop"
                width={28}
                height={28}
              />
              <span className="text-[15px] font-black text-white">
                TheDailyPoop
              </span>
            </div>
            <p className="mt-2 max-w-xs text-[13px] text-zinc-500 sm:text-left text-center leading-relaxed">
              25 stories a day. Zero boring ones. News that actually makes you
              laugh.
            </p>
          </div>

          {/* Links */}
          <div className="flex gap-10">
            <div className="flex flex-col gap-2">
              <span className="text-[10px] font-bold uppercase tracking-widest text-zinc-600">
                Read
              </span>
              <Link
                href="/today"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Today
              </Link>
              <Link
                href="/archive"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Archive
              </Link>
              <Link
                href="/games"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Games
              </Link>
            </div>
            <div className="flex flex-col gap-2">
              <span className="text-[10px] font-bold uppercase tracking-widest text-zinc-600">
                More
              </span>
              <a
                href="https://apps.apple.com/app/thedailypoop/id6738030377"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                iPhone App
              </a>
              <Link
                href="/advertise"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Advertise
              </Link>
              <Link
                href="/legal/privacy"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Privacy
              </Link>
              <Link
                href="/legal/terms"
                className="text-[13px] text-zinc-500 hover:text-white transition"
              >
                Terms
              </Link>
            </div>
          </div>
        </div>

        <div className="mx-auto mt-8 max-w-6xl border-t border-white/[0.04] pt-6 text-center">
          <p className="text-[11px] text-zinc-600">
            &copy; {new Date().getFullYear()} TheDailyPoop. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
