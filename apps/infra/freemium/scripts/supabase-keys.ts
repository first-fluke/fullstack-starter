import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const _dirname = dirname(fileURLToPath(import.meta.url));
void _dirname; // unused here but mirrors project convention

const SUPABASE_API_BASE = "https://api.supabase.com/v1";
const MAX_ATTEMPTS = 3;
const BASE_DELAY_MS = 2000;

export interface SupabaseApiKey {
  name: string;
  api_key: string;
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function getSupabaseKeys(
  projectId: string,
): Promise<SupabaseApiKey[]> {
  const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
  if (!accessToken) {
    console.error(
      "Missing required environment variable: SUPABASE_ACCESS_TOKEN",
    );
    process.exit(1);
  }

  const url = `${SUPABASE_API_BASE}/projects/${projectId}/api-keys`;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      const keys = (await response.json()) as SupabaseApiKey[];
      return keys;
    }

    const status = response.status;
    const body = await response.text();

    if (attempt < MAX_ATTEMPTS) {
      const delayMs = BASE_DELAY_MS * Math.pow(2, attempt - 1);
      console.error(
        `Attempt ${attempt}/${MAX_ATTEMPTS} failed (HTTP ${status}). Retrying in ${delayMs / 1000}s...`,
      );
      if (body) {
        console.error("Response:", body);
      }
      await sleep(delayMs);
    } else {
      console.error(
        `All ${MAX_ATTEMPTS} attempts failed. Last response (HTTP ${status}):`,
      );
      if (body) {
        console.error(body);
      }
      process.exit(1);
    }
  }

  // Unreachable — process.exit above handles the failure path.
  return [];
}

async function main(): Promise<void> {
  const projectId = process.argv[2];

  if (!projectId) {
    console.error("Usage: bun run supabase-keys.ts <project_id>");
    process.exit(1);
  }

  const keys = await getSupabaseKeys(projectId);
  process.stdout.write(JSON.stringify(keys, null, 2) + "\n");
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error("Unexpected error:", message);
  process.exit(1);
});
