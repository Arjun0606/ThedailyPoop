import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";
import { validateUserRequest } from "@/lib/user-auth";

export async function POST(request: NextRequest) {
  const db = createServiceClient();

  // Clone request to read auth header before consuming form data
  const auth = await validateUserRequest(request);
  if (auth instanceof NextResponse) return auth;

  const formData = await request.formData();
  const userId = formData.get("userId") as string;
  const file = formData.get("file") as File;

  if (!userId || !file) {
    return NextResponse.json(
      { error: "Missing required fields: userId, file" },
      { status: 400 }
    );
  }

  // Verify the token matches the userId
  if (auth.userId !== userId) {
    return NextResponse.json(
      { error: "Forbidden: token does not match userId" },
      { status: 403 }
    );
  }

  const fileName = `${userId}.jpg`;
  const buffer = Buffer.from(await file.arrayBuffer());

  // Upload to storage (service client bypasses storage RLS)
  const { error: uploadError } = await db.storage
    .from("avatars")
    .upload(fileName, buffer, {
      contentType: "image/jpeg",
      upsert: true,
    });

  if (uploadError) {
    return NextResponse.json(
      { error: `Upload failed: ${uploadError.message}` },
      { status: 500 }
    );
  }

  // Get public URL
  const { data: urlData } = db.storage.from("avatars").getPublicUrl(fileName);

  return NextResponse.json({
    success: true,
    avatarUrl: urlData.publicUrl,
  });
}
