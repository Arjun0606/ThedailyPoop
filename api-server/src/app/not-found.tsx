import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-black">
      <Header />
      <main className="flex flex-col items-center justify-center px-4 py-32 text-center">
        <span className="text-6xl">💩</span>
        <h1 className="mt-4 text-3xl font-black text-white">404 — Page Not Found</h1>
        <p className="mt-2 text-sm text-zinc-500">
          This page doesn&apos;t exist. Maybe it never did.
        </p>
        <Link
          href="/today"
          className="pressable mt-6 inline-block rounded-full bg-[var(--accent)] px-6 py-2.5 text-sm font-bold text-black transition hover:bg-[var(--accent-hover)]"
        >
          Back to today&apos;s stories
        </Link>
      </main>
      <Footer />
    </div>
  );
}
