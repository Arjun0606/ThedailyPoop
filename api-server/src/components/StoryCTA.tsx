export default function StoryCTA() {
  return (
    <div className="rounded-2xl border border-[var(--accent)]/20 bg-[var(--accent-dim)] p-6 text-center">
      <p className="text-2xl">💩</p>
      <h3 className="mt-2 text-lg font-black text-white">
        Get the Full Experience
      </h3>
      <p className="mt-1 text-sm text-[var(--text-secondary)]">
        All 25 daily stories, 5 AI-powered games, audio narration, and zero ads.
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
