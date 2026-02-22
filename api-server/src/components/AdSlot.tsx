"use client";

import { useEffect, useRef } from "react";

interface AdSlotProps {
  format?: "auto" | "horizontal" | "vertical" | "rectangle";
  className?: string;
}

export default function AdSlot({
  format = "auto",
  className = "",
}: AdSlotProps) {
  const adRef = useRef<HTMLModElement>(null);

  useEffect(() => {
    if (typeof window !== "undefined" && process.env.NEXT_PUBLIC_ADSENSE_ID) {
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        ((window as any).adsbygoogle = (window as any).adsbygoogle || []).push(
          {}
        );
      } catch {
        // AdSense not loaded
      }
    }
  }, []);

  // Don't render if no AdSense ID configured
  if (!process.env.NEXT_PUBLIC_ADSENSE_ID) {
    return null;
  }

  return (
    <div className={`my-6 flex justify-center ${className}`}>
      <ins
        ref={adRef}
        className="adsbygoogle"
        style={{ display: "block" }}
        data-ad-client={process.env.NEXT_PUBLIC_ADSENSE_ID}
        data-ad-slot=""
        data-ad-format={format}
        data-full-width-responsive="true"
      />
    </div>
  );
}
