import { env } from "@/config/env";

const splitList = (value: string) =>
  value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

export const dynamic = "force-dynamic";

export function GET() {
  return Response.json(
    [
      {
        relation: ["delegate_permission/common.get_login_creds"],
        target: {
          namespace: "android_app",
          package_name: env.MOBILE_ANDROID_PACKAGE_NAME,
          sha256_cert_fingerprints: splitList(env.MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS),
        },
      },
    ],
    {
      headers: {
        "Cache-Control": "public, max-age=300",
      },
    }
  );
}
