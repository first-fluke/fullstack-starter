import {
  existsSync,
  readFileSync,
  appendFileSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { getSupabaseKeys } from "./supabase-keys.ts";

const __dirname = dirname(fileURLToPath(import.meta.url));
const HACKATHON_DIR = resolve(__dirname, "..");
const REPO_ROOT = resolve(__dirname, "../../..");

const VERCEL_API_BASE = "https://api.vercel.com";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TerraformOutput {
  value: unknown;
  type?: string;
  sensitive?: boolean;
}

interface TerraformOutputs {
  vercel_api_project_id: TerraformOutput;
  vercel_web_project_id: TerraformOutput;
  supabase_project_id: TerraformOutput;
  supabase_url: TerraformOutput;
  b2_bucket_name: TerraformOutput;
  b2_key_id: TerraformOutput;
  b2_app_key: TerraformOutput;
}

interface WeaviateState {
  cluster_id: string;
  url: string;
  api_key: string;
}

interface VercelEnvVar {
  key: string;
  id?: string;
}

interface VercelEnvListResponse {
  envs: VercelEnvVar[];
}

// ---------------------------------------------------------------------------
// Environment validation
// ---------------------------------------------------------------------------

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    console.error(`Missing required environment variable: ${name}`);
    process.exit(1);
  }
  return value;
}

// ---------------------------------------------------------------------------
// Step 1: Terraform outputs
// ---------------------------------------------------------------------------

async function collectTerraformOutputs(): Promise<TerraformOutputs> {
  console.log("Collecting Terraform outputs...");

  const proc = Bun.spawn(["terraform", "output", "-json"], {
    cwd: HACKATHON_DIR,
    stdout: "pipe",
    stderr: "pipe",
  });

  const exitCode = await proc.exited;
  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();

  if (exitCode !== 0) {
    console.error("terraform output failed:");
    console.error(stderr);
    process.exit(1);
  }

  let parsed: Record<string, TerraformOutput>;
  try {
    parsed = JSON.parse(stdout) as Record<string, TerraformOutput>;
  } catch {
    console.error("Failed to parse terraform output JSON.");
    console.error("Raw output:", stdout);
    process.exit(1);
  }

  const required = [
    "vercel_api_project_id",
    "vercel_web_project_id",
    "supabase_project_id",
    "supabase_url",
    "b2_bucket_name",
    "b2_key_id",
    "b2_app_key",
  ] as const;

  for (const key of required) {
    if (!(key in parsed)) {
      console.error(`Missing expected terraform output: ${key}`);
      process.exit(1);
    }
  }

  return parsed as unknown as TerraformOutputs;
}

function tfString(output: TerraformOutput): string {
  return String(output.value);
}

// ---------------------------------------------------------------------------
// Step 3: Weaviate state
// ---------------------------------------------------------------------------

function collectWeaviateState(): WeaviateState {
  const statePath = join(HACKATHON_DIR, ".weaviate-state.json");

  if (!existsSync(statePath)) {
    console.error(`Weaviate state file not found: ${statePath}`);
    console.error("Run `bun run weaviate.ts up` first.");
    process.exit(1);
  }

  let state: WeaviateState;
  try {
    const raw = readFileSync(statePath, "utf-8");
    state = JSON.parse(raw) as WeaviateState;
  } catch {
    console.error("Failed to parse .weaviate-state.json.");
    process.exit(1);
  }

  if (!state.url || !state.api_key) {
    console.error(".weaviate-state.json is missing url or api_key fields.");
    process.exit(1);
  }

  return state;
}

// ---------------------------------------------------------------------------
// Step 4: Vercel env injection
// ---------------------------------------------------------------------------

async function getExistingVercelKeys(
  projectId: string,
  token: string,
): Promise<Set<string>> {
  const response = await fetch(
    `${VERCEL_API_BASE}/v9/projects/${projectId}/env`,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    },
  );

  if (!response.ok) {
    const body = await response.text();
    console.error(
      `Failed to list Vercel env vars for project ${projectId} (HTTP ${response.status}):`,
    );
    console.error(body);
    process.exit(1);
  }

  const data = (await response.json()) as VercelEnvListResponse;
  return new Set((data.envs ?? []).map((e) => e.key));
}

async function addVercelEnvVar(
  projectId: string,
  token: string,
  key: string,
  value: string,
): Promise<void> {
  const response = await fetch(
    `${VERCEL_API_BASE}/v10/projects/${projectId}/env`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key,
        value,
        target: ["production", "preview"],
        type: "encrypted",
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    console.error(
      `Failed to add Vercel env var ${key} to project ${projectId} (HTTP ${response.status}):`,
    );
    console.error(body);
    process.exit(1);
  }
}

async function injectVercelEnvVars(
  projectId: string,
  token: string,
  vars: Record<string, string>,
  label: string,
): Promise<void> {
  console.log(`\nChecking Vercel env vars for ${label} (${projectId})...`);

  const existing = await getExistingVercelKeys(projectId, token);

  for (const [key, value] of Object.entries(vars)) {
    if (existing.has(key)) {
      console.log(`  [skip] ${key} already exists`);
    } else {
      await addVercelEnvVar(projectId, token, key, value);
      console.log(`  [added] ${key}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Step 5: .env.example update
// ---------------------------------------------------------------------------

function ensureEnvExampleKeys(filePath: string, keys: string[]): void {
  let content = "";

  try {
    content = readFileSync(filePath, "utf-8");
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code !== "ENOENT") throw err;
    console.log(`  [created] ${filePath}`);
  }

  const missing = keys.filter(
    (key) => !content.split("\n").some((line) => line.startsWith(`${key}=`)),
  );

  if (missing.length === 0) {
    console.log(`  [ok] ${filePath} — all keys present`);
    return;
  }

  const toAppend =
    (content.endsWith("\n") || content === "" ? "" : "\n") +
    missing.map((k) => `${k}=`).join("\n") +
    "\n";

  writeFileSync(filePath, content + toAppend, "utf-8");

  for (const key of missing) {
    console.log(`  [added] ${key} to ${filePath}`);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const vercelToken = requireEnv("VERCEL_API_TOKEN");
  requireEnv("SUPABASE_ACCESS_TOKEN"); // validated early; used inside getSupabaseKeys

  // Step 1: Terraform outputs
  const tf = await collectTerraformOutputs();

  const vercelApiProjectId = tfString(tf.vercel_api_project_id);
  const vercelWebProjectId = tfString(tf.vercel_web_project_id);
  const supabaseProjectId = tfString(tf.supabase_project_id);
  const supabaseUrl = tfString(tf.supabase_url);
  const b2BucketName = tfString(tf.b2_bucket_name);
  const b2KeyId = tfString(tf.b2_key_id);
  const b2AppKey = tfString(tf.b2_app_key);

  console.log("Terraform outputs collected.");

  // Step 2: Supabase keys
  console.log("\nFetching Supabase API keys...");
  const supabaseKeys = await getSupabaseKeys(supabaseProjectId);
  const anonEntry = supabaseKeys.find((k) => k.name === "anon");

  if (!anonEntry) {
    console.error(
      'Supabase anon key not found. Available keys:',
      supabaseKeys.map((k) => k.name).join(", "),
    );
    process.exit(1);
  }

  const supabaseAnonKey = anonEntry.api_key;
  console.log("Supabase anon key retrieved.");

  // Step 3: Weaviate state
  console.log("\nReading Weaviate state...");
  const weaviate = collectWeaviateState();
  console.log("Weaviate state loaded.");

  // Step 4: Vercel env injection
  await injectVercelEnvVars(
    vercelApiProjectId,
    vercelToken,
    {
      WEAVIATE_URL: weaviate.url,
      WEAVIATE_API_KEY: weaviate.api_key,
      SUPABASE_ANON_KEY: supabaseAnonKey,
    },
    "API project",
  );

  await injectVercelEnvVars(
    vercelWebProjectId,
    vercelToken,
    {
      WEAVIATE_URL: weaviate.url,
      NEXT_PUBLIC_SUPABASE_ANON_KEY: supabaseAnonKey,
    },
    "Web project",
  );

  // Step 5: .env.example updates
  console.log("\nUpdating .env.example files...");

  const apiEnvExample = join(REPO_ROOT, "apps", "api", ".env.example");
  ensureEnvExampleKeys(apiEnvExample, [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "WEAVIATE_URL",
    "WEAVIATE_API_KEY",
    "B2_KEY_ID",
    "B2_APPLICATION_KEY",
    "B2_BUCKET_NAME",
  ]);

  const webEnvExample = join(REPO_ROOT, "apps", "web", ".env.example");
  ensureEnvExampleKeys(webEnvExample, [
    "NEXT_PUBLIC_SUPABASE_URL",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  ]);

  console.log("\nenv-sync complete.");
  console.log("  Supabase URL     :", supabaseUrl);
  console.log("  B2 bucket        :", b2BucketName);
  console.log("  B2 key ID        :", b2KeyId);
  console.log("  B2 app key       : [redacted]", b2AppKey ? "(set)" : "(empty)");
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error("Unexpected error:", message);
  process.exit(1);
});
