/**
 * Fetches Open Graph image URL from a web page.
 * Used during briefing generation to get article hero images.
 */
export async function fetchOgImage(url: string): Promise<string | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        "User-Agent":
          "Mozilla/5.0 (compatible; TheDailyPoop/1.0; +https://thedailypoop.com)",
      },
      redirect: "follow",
    });
    clearTimeout(timeout);

    if (!res.ok) return null;

    // Only read first 50KB to find meta tags (they're always in <head>)
    const reader = res.body?.getReader();
    if (!reader) return null;

    let html = "";
    const decoder = new TextDecoder();
    while (html.length < 50000) {
      const { done, value } = await reader.read();
      if (done) break;
      html += decoder.decode(value, { stream: true });
      // Stop early if we've passed </head>
      if (html.includes("</head>")) break;
    }
    reader.cancel();

    // Parse og:image from meta tags
    const ogMatch = html.match(
      /<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i
    );
    if (ogMatch) return ogMatch[1];

    // Try reverse attribute order (content before property)
    const reverseMatch = html.match(
      /<meta[^>]*content=["']([^"']+)["'][^>]*property=["']og:image["']/i
    );
    if (reverseMatch) return reverseMatch[1];

    return null;
  } catch {
    return null;
  }
}

/**
 * Fetches OG images for multiple URLs in parallel.
 * Returns a map of sourceUrl → imageUrl.
 */
export async function fetchOgImages(
  urls: string[]
): Promise<Map<string, string>> {
  const results = new Map<string, string>();

  const settled = await Promise.allSettled(
    urls.map(async (url) => {
      const image = await fetchOgImage(url);
      return { url, image };
    })
  );

  for (const result of settled) {
    if (result.status === "fulfilled" && result.value.image) {
      results.set(result.value.url, result.value.image);
    }
  }

  return results;
}
