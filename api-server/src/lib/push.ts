import { createServiceClient } from "./supabase";

// APNs push notification sender
// Uses APNs HTTP/2 API directly — no heavy SDK needed

const APNS_HOST = process.env.APNS_PRODUCTION === "true"
  ? "api.push.apple.com"
  : "api.sandbox.push.apple.com";

const BUNDLE_ID = process.env.APPLE_BUNDLE_ID ?? "com.arjun.PoopDrop";

interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  sound?: string;
  badge?: number;
}

// Send push notification to a single device token
async function sendToToken(token: string, payload: PushPayload): Promise<boolean> {
  const teamId = process.env.APPLE_TEAM_ID;
  const keyId = process.env.APPLE_KEY_ID;
  const key = process.env.APPLE_PUSH_KEY; // p8 key content

  if (!teamId || !keyId || !key) {
    console.log("⚠️ APNs not configured — skipping push to", token.substring(0, 8) + "...");
    return false;
  }

  // Build JWT for APNs auth
  const jwt = await buildAPNsJWT(teamId, keyId, key);

  const apnsPayload = {
    aps: {
      alert: {
        title: payload.title,
        body: payload.body,
      },
      sound: payload.sound ?? "default",
      ...(payload.badge !== undefined ? { badge: payload.badge } : {}),
    },
    ...(payload.data ?? {}),
  };

  try {
    const response = await fetch(`https://${APNS_HOST}/3/device/${token}`, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
      },
      body: JSON.stringify(apnsPayload),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`❌ APNs error for ${token.substring(0, 8)}...:`, error);
      return false;
    }

    return true;
  } catch (error) {
    console.error("❌ APNs request failed:", error);
    return false;
  }
}

// Build ES256 JWT for APNs authentication
async function buildAPNsJWT(teamId: string, keyId: string, key: string): Promise<string> {
  const header = btoa(JSON.stringify({ alg: "ES256", kid: keyId }))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const now = Math.floor(Date.now() / 1000);
  const claims = btoa(JSON.stringify({ iss: teamId, iat: now }))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  // Import the P8 key
  const pemKey = key.includes("BEGIN PRIVATE KEY")
    ? key
    : `-----BEGIN PRIVATE KEY-----\n${key}\n-----END PRIVATE KEY-----`;

  const keyData = pemKey
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const data = new TextEncoder().encode(`${header}.${claims}`);
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    data
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  return `${header}.${claims}.${sig}`;
}

// Send push to all members of a group
export async function pushToGroup(
  groupId: string,
  payload: PushPayload,
  excludeUserId?: string
): Promise<number> {
  const db = createServiceClient();

  // Get all group members' device tokens
  const { data: members } = await db
    .from("group_members")
    .select("user_id")
    .eq("group_id", groupId);

  if (!members?.length) return 0;

  const userIds = members
    .map((m) => m.user_id)
    .filter((id: string) => id !== excludeUserId);

  if (!userIds.length) return 0;

  const { data: tokens } = await db
    .from("device_tokens")
    .select("token")
    .in("user_id", userIds);

  if (!tokens?.length) return 0;

  let sent = 0;
  for (const { token } of tokens) {
    const ok = await sendToToken(token, payload);
    if (ok) sent++;
  }

  console.log(`📱 Pushed to ${sent}/${tokens.length} devices in group ${groupId}`);
  return sent;
}

// Send push to a specific user
export async function pushToUser(
  userId: string,
  payload: PushPayload
): Promise<boolean> {
  const db = createServiceClient();

  const { data: tokens } = await db
    .from("device_tokens")
    .select("token")
    .eq("user_id", userId);

  if (!tokens?.length) return false;

  let sent = false;
  for (const { token } of tokens) {
    const ok = await sendToToken(token, payload);
    if (ok) sent = true;
  }

  return sent;
}

// Send push to multiple users
export async function pushToUsers(
  userIds: string[],
  payload: PushPayload
): Promise<number> {
  const db = createServiceClient();

  const { data: tokens } = await db
    .from("device_tokens")
    .select("token, user_id")
    .in("user_id", userIds);

  if (!tokens?.length) return 0;

  let sent = 0;
  for (const { token } of tokens) {
    const ok = await sendToToken(token, payload);
    if (ok) sent++;
  }

  return sent;
}
