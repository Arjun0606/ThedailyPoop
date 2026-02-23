"use client";

import { useState, useEffect } from "react";

function getNextDrop(hasBriefing: boolean): Date {
  const now = new Date();
  const et = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/New_York",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(now);

  const parts: Record<string, string> = {};
  for (const p of et) {
    if (p.type !== "literal") parts[p.type] = p.value;
  }

  // Build today's 7 AM ET as a UTC date
  const etYear = parseInt(parts.year);
  const etMonth = parseInt(parts.month) - 1;
  const etDay = parseInt(parts.day);
  const etHour = parseInt(parts.hour);

  // Create a date for today 7 AM ET
  // We use a trick: get the offset by comparing ET components to UTC
  const todayET = new Date(now);

  // Calculate: if we have a briefing OR it's past 7 AM ET, target tomorrow 7 AM
  const isPast7AM = etHour >= 7;

  if (hasBriefing || isPast7AM) {
    // Tomorrow 7 AM ET
    const tomorrow = new Date(
      Date.UTC(etYear, etMonth, etDay + 1, 12, 0, 0)
    );
    // Find exact 7 AM ET tomorrow by adjusting
    const offset = getETOffset(tomorrow);
    return new Date(Date.UTC(etYear, etMonth, etDay + 1, 7 + offset, 0, 0));
  } else {
    // Today 7 AM ET
    const offset = getETOffset(now);
    return new Date(Date.UTC(etYear, etMonth, etDay, 7 + offset, 0, 0));
  }
}

function getETOffset(date: Date): number {
  // Get UTC offset for America/New_York at the given date
  // EST = UTC-5, EDT = UTC-4
  const jan = new Date(date.getFullYear(), 0, 1);
  const jul = new Date(date.getFullYear(), 6, 1);
  const stdOffset = Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset());
  const etFormatter = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/New_York",
    hour: "numeric",
    hour12: false,
  });
  // Simple approach: EST is +5, EDT is +4
  // Check if date is in DST
  const utcHour = date.getUTCHours();
  const etParts = etFormatter.formatToParts(date);
  const etHour = parseInt(etParts.find((p) => p.type === "hour")?.value || "0");
  const diff = ((utcHour - etHour) % 24 + 24) % 24;
  return diff > 12 ? diff - 24 : diff;
}

function formatCountdown(diffMs: number): string {
  if (diffMs <= 0) return "0:00:00";
  const totalSec = Math.floor(diffMs / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

export default function NextDropTimer({
  hasBriefing,
}: {
  hasBriefing: boolean;
}) {
  const [countdown, setCountdown] = useState("");

  useEffect(() => {
    function update() {
      const target = getNextDrop(hasBriefing);
      const diff = target.getTime() - Date.now();
      setCountdown(formatCountdown(diff));
    }

    update();
    const interval = setInterval(update, 1000);
    return () => clearInterval(interval);
  }, [hasBriefing]);

  if (!countdown) return null;

  return (
    <div className="flex items-center gap-2 text-xs text-[var(--text-tertiary)]">
      <span className="inline-block h-1.5 w-1.5 rounded-full bg-[var(--accent)] animate-pulse" />
      <span>
        {hasBriefing ? "Next drop in" : "Drop in"}{" "}
        <span className="font-mono font-bold text-[var(--accent)]">
          {countdown}
        </span>
      </span>
    </div>
  );
}
