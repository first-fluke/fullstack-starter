import { env } from "@/config/env";

export const dynamic = "force-dynamic";

export function GET() {
  const apps = env.MOBILE_APPLE_APP_IDS.split(",")
    .map((item) => item.trim())
    .filter(Boolean);

  return Response.json(
    { webcredentials: { apps } },
    {
      headers: {
        "Cache-Control": "public, max-age=300",
      },
    }
  );
}
