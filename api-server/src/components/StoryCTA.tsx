export default function StoryCTA() {
  return (
    <div className="rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-6 text-center">
      <p className="text-2xl">💩</p>
      <h3 className="mt-2 text-lg font-black text-white">
        Play the Games. Get the App.
      </h3>
      <p className="mt-1 text-sm text-[var(--text-secondary)]">
        6 AI-powered games daily, audio narration, push alerts, and the
        smoothest news experience on your phone. One free game — Pro unlocks
        everything.
      </p>
      <a
        href="https://apps.apple.com/app/thedailypoop/id6738030377"
        target="_blank"
        rel="noopener noreferrer"
        className="mt-4 inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:brightness-110"
      >
        Download Free on iPhone
      </a>
    </div>
  );
}
