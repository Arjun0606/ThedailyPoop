import Image from "next/image";

export default function StoryCTA() {
  return (
    <div className="glass-card overflow-hidden">
      <div className="bg-gradient-to-r from-[var(--accent)]/10 to-transparent p-6 sm:flex sm:items-center sm:gap-6 sm:p-8">
        <Image
          src="/logo.png"
          alt="TheDailyPoop"
          width={64}
          height={64}
          className="mx-auto drop-shadow-lg sm:mx-0"
        />
        <div className="mt-4 text-center sm:mt-0 sm:text-left">
          <h3 className="text-lg font-black text-white">
            The app is coming.
          </h3>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            6 AI-powered games daily, audio narration, push alerts, and the
            smoothest news experience on your phone. Launching soon on iOS.
          </p>
          <span className="mt-4 inline-block rounded-full bg-zinc-800 px-5 py-2 text-sm font-bold text-zinc-400">
            iOS App Coming Soon
          </span>
        </div>
      </div>
    </div>
  );
}
