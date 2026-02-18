import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase";

export async function POST(request: NextRequest) {
  const db = createServiceClient();

  const formData = await request.formData();
  const userId = formData.get("userId") as string;
  const file = formData.get("file") as File;

  if (!userId || !file) {
    return NextResponse.json(
      { error: "Missing required fields: userId, file" },
      { status: 400 }
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
