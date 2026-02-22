const BEEHIIV_API = "https://api.beehiiv.com/v2";

function headers() {
  return {
    Authorization: `Bearer ${process.env.BEEHIIV_API_KEY}`,
    "Content-Type": "application/json",
  };
}

function pubId() {
  return process.env.BEEHIIV_PUBLICATION_ID!;
}

// Subscribe an email to the newsletter
export async function subscribeToBeehiiv(
  email: string,
  source: string = "website"
) {
  const res = await fetch(
    `${BEEHIIV_API}/publications/${pubId()}/subscriptions`,
    {
      method: "POST",
      headers: headers(),
      body: JSON.stringify({
        email: email.toLowerCase().trim(),
        reactivate_existing: true,
        send_welcome_email: true,
        utm_source: source,
        utm_medium: "organic",
      }),
    }
  );

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Beehiiv subscribe failed: ${res.status}`);
  }

  return res.json();
}

// Create and optionally publish a post (daily newsletter)
export async function createBeehiivPost({
  title,
  subtitle,
  html,
  sendNow = false,
}: {
  title: string;
  subtitle?: string;
  html: string;
  sendNow?: boolean;
}) {
  const res = await fetch(
    `${BEEHIIV_API}/publications/${pubId()}/posts`,
    {
      method: "POST",
      headers: headers(),
      body: JSON.stringify({
        title,
        subtitle,
        content: [{ type: "html", html }],
        status: sendNow ? "confirmed" : "draft",
        // Beehiiv Ad Network will auto-inject ads for monetization
      }),
    }
  );

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Beehiiv post failed: ${res.status}`);
  }

  return res.json();
}
