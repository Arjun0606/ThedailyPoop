import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "TheDailyPoop — News That Doesn't Suck",
    template: "%s | TheDailyPoop",
  },
  description:
    "25 stories a day, zero boring ones. Dark satirical news briefings, AI-powered games, and a daily ritual that actually makes you laugh. Free on iPhone.",
  metadataBase: new URL("https://thedailypoop.lol"),
  openGraph: {
    type: "website",
    siteName: "TheDailyPoop",
    locale: "en_US",
    images: [
      {
        url: "/api/og?title=TheDailyPoop%20%E2%80%94%20News%20That%20Doesn%27t%20Suck&emoji=%F0%9F%93%B0&category=default",
        width: 1200,
        height: 630,
        alt: "TheDailyPoop — News That Doesn't Suck",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    creator: "@thedailypoop",
  },
  robots: {
    index: true,
    follow: true,
    "max-image-preview": "large",
    "max-snippet": -1,
    "max-video-preview": -1,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "32x32" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/apple-icon.png", sizes: "180x180", type: "image/png" }],
  },
  alternates: {
    types: { "application/rss+xml": "/feed.xml" },
    canonical: "https://thedailypoop.lol",
  },
  other: {
    "google-site-verification": process.env.GOOGLE_SITE_VERIFICATION || "",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        {/* Google AdSense — activate when approved */}
        {process.env.NEXT_PUBLIC_ADSENSE_ID && (
          <script
            async
            src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${process.env.NEXT_PUBLIC_ADSENSE_ID}`}
            crossOrigin="anonymous"
          />
        )}
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-[var(--background)] text-[var(--foreground)]`}
      >
        {children}
      </body>
    </html>
  );
}
