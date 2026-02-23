type Segment =
  | { type: "text"; content: string }
  | { type: "translation"; content: string }
  | { type: "the_number"; content: string }
  | { type: "bottom_line"; content: string };

function parseBody(body: string): { segments: Segment[]; bottomLine: string | null } {
  const paragraphs = body.split("\n\n");
  const segments: Segment[] = [];
  let bottomLine: string | null = null;

  for (const raw of paragraphs) {
    const trimmed = raw.trim();
    if (!trimmed) continue;

    // The Bottom Line — extract separately, render at end
    if (/^the bottom line:/i.test(trimmed)) {
      bottomLine = trimmed.replace(/^the bottom line:\s*/i, "");
      continue;
    }

    // Translation — inline or paragraph-level
    if (/^translation:/i.test(trimmed)) {
      segments.push({ type: "translation", content: trimmed.replace(/^translation:\s*/i, "") });
      continue;
    }

    // Check if Translation appears mid-paragraph (after a newline)
    if (/\ntranslation:/i.test(trimmed)) {
      const idx = trimmed.search(/\ntranslation:/i);
      const textBefore = trimmed.slice(0, idx).trim();
      const translationContent = trimmed.slice(idx).replace(/^\ntranslation:\s*/i, "").trim();
      if (textBefore) segments.push({ type: "text", content: textBefore });
      if (translationContent) segments.push({ type: "translation", content: translationContent });
      continue;
    }

    // The Number
    if (/^the number:/i.test(trimmed)) {
      segments.push({ type: "the_number", content: trimmed.replace(/^the number:\s*/i, "") });
      continue;
    }

    // Regular text
    segments.push({ type: "text", content: trimmed });
  }

  return { segments, bottomLine };
}

export default function StoryBody({ body, tldr }: { body: string; tldr?: string | null }) {
  const { segments, bottomLine } = parseBody(body);

  return (
    <div className="mt-6 space-y-5">
      {segments.map((seg, i) => {
        switch (seg.type) {
          case "translation":
            return (
              <div key={i} className="rounded-xl border border-cyan-500/15 bg-cyan-500/[0.04] p-4 pl-5 border-l-[3px] border-l-cyan-400">
                <p className="text-[10px] font-bold uppercase tracking-[0.15em] text-cyan-400">Translation</p>
                <p className="mt-1.5 text-[15px] font-medium leading-relaxed text-zinc-200">{seg.content}</p>
              </div>
            );

          case "the_number":
            return (
              <div key={i} className="rounded-xl border border-[var(--accent)]/15 bg-[var(--accent)]/[0.04] p-4 pl-5 border-l-[3px] border-l-[var(--accent)]">
                <p className="text-[10px] font-bold uppercase tracking-[0.15em] text-[var(--accent)]">The Number</p>
                <p className="mt-1.5 text-[15px] font-bold leading-relaxed text-white">{seg.content}</p>
              </div>
            );

          default:
            return (
              <p key={i} className="text-base leading-relaxed text-zinc-300">
                {seg.content}
              </p>
            );
        }
      })}

      {/* The Bottom Line — always last */}
      {bottomLine && (
        <div className="rounded-xl border border-[var(--accent)]/20 bg-[var(--accent)]/[0.05] p-5 pl-5 border-l-[3px] border-l-[var(--accent)]">
          <p className="text-[10px] font-bold uppercase tracking-[0.15em] text-[var(--accent)]">The Bottom Line</p>
          <p className="mt-2 text-[15px] font-bold leading-snug text-white">{bottomLine}</p>
        </div>
      )}

      {/* TLDR */}
      {tldr && (
        <div className="rounded-xl border border-[var(--accent)]/10 bg-[var(--accent)]/[0.03] p-4">
          <p className="text-[10px] font-bold uppercase tracking-[0.15em] text-[var(--accent)]">TLDR</p>
          <p className="mt-1.5 text-sm italic leading-relaxed text-zinc-400">{tldr}</p>
        </div>
      )}
    </div>
  );
}
