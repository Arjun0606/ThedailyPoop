import { NextRequest } from "next/server";

// Beehiiv handles unsubscribe natively via their email footer links.
// This route is a fallback for any legacy unsubscribe links.
export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl;
  const email = searchParams.get("email") || searchParams.get("id") || "";

  return new Response(
    `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Unsubscribed | TheDailyPoop</title></head>
<body style="margin:0;padding:0;background:#000;color:#fff;font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;">
  <div style="text-align:center;padding:40px;">
    <div style="font-size:48px;margin-bottom:16px;">💩</div>
    <p style="font-size:18px;font-weight:700;">You've been unsubscribed. We'll miss you.</p>
    <p style="font-size:14px;color:#a1a1aa;margin-top:8px;">
      ${email ? `(${email})` : ""}
    </p>
    <a href="https://thedailypoop.lol" style="display:inline-block;margin-top:16px;color:#F59E0B;font-size:14px;">
      Back to TheDailyPoop
    </a>
  </div>
</body>
</html>`,
    { headers: { "Content-Type": "text/html" } }
  );
}
