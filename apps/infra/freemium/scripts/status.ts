import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const HACKATHON_DIR = join(__dirname, "..");
const STATE_FILE = join(HACKATHON_DIR, ".weaviate-state.json");
const TIMEOUT_MS = 5_000;

function validateUrl(value: string, name: string): string {
  const parsed = URL.parse(value);
  if (!parsed || !["http:", "https:"].includes(parsed.protocol ?? "")) {
    throw new Error(`Invalid ${name} URL: ${value}`);
  }
  return parsed.href;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TerraformOutput {
  value: unknown;
  sensitive?: boolean;
}

interface TerraformOutputs {
  vercel_api_project_id?: TerraformOutput;
  vercel_web_project_id?: TerraformOutput;
  supabase_project_id?: TerraformOutput;
  b2_bucket_name?: TerraformOutput;
}

interface WeaviateState {
  url: string;
}

type StatusSymbol = "✓" | "✗" | "–";

interface ServiceResult {
  label: string;
  symbol: StatusSymbol;
  detail: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function tfString(output: TerraformOutput | undefined): string | null {
  if (!output) return null;
  const v = output.value;
  if (typeof v === "string" && v.length > 0) return v;
  return null;
}

function pad(label: string, width: number): string {
  return label.padEnd(width, " ");
}

async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

function errorMessage(err: unknown): string {
  if (err instanceof Error) {
    if (err.name === "AbortError") return "timed out after 5s";
    return err.message;
  }
  return String(err);
}

// ---------------------------------------------------------------------------
// Data sources
// ---------------------------------------------------------------------------

async function collectTerraformOutputs(): Promise<TerraformOutputs | null> {
  const proc = Bun.spawn(["terraform", "output", "-json"], {
    cwd: HACKATHON_DIR,
    stdout: "pipe",
    stderr: "pipe",
  });

  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    return null;
  }

  const stdout = await new Response(proc.stdout).text();

  try {
    return JSON.parse(stdout) as TerraformOutputs;
  } catch {
    return null;
  }
}

function readWeaviateState(): WeaviateState | null {
  if (!existsSync(STATE_FILE)) return null;
  try {
    const raw = readFileSync(STATE_FILE, "utf-8");
    const parsed = JSON.parse(raw) as WeaviateState;
    if (typeof parsed?.url === "string" && parsed.url.length > 0) {
      return parsed;
    }
    return null;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Individual checks
// ---------------------------------------------------------------------------

async function checkVercelProject(
  projectId: string,
  token: string,
): Promise<{ ok: boolean; error?: string }> {
  const url = validateUrl(`https://api.vercel.com/v9/projects/${encodeURIComponent(projectId)}`, "Vercel API");
  try {
    const res = await fetchWithTimeout(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (res.ok) return { ok: true };
    return { ok: false, error: `HTTP ${res.status}` };
  } catch (err) {
    return { ok: false, error: errorMessage(err) };
  }
}

async function checkSupabase(
  projectId: string,
): Promise<{ ok: boolean; error?: string }> {
  const url = validateUrl(`https://${encodeURIComponent(projectId)}.supabase.co`, "Supabase");
  try {
    const res = await fetchWithTimeout(url);
    if (res.status < 500) return { ok: true };
    return { ok: false, error: `HTTP ${res.status}` };
  } catch (err) {
    return { ok: false, error: errorMessage(err) };
  }
}

async function checkWeaviate(
  weaviateUrl: string,
): Promise<{ ok: boolean; error?: string }> {
  const base = validateUrl(weaviateUrl, "Weaviate").replace(/\/$/, "");
  const url = `${base}/.well-known/ready`;
  try {
    const res = await fetchWithTimeout(url);
    if (res.ok) return { ok: true };
    return { ok: false, error: `HTTP ${res.status}` };
  } catch (err) {
    return { ok: false, error: errorMessage(err) };
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const vercelToken = process.env.VERCEL_API_TOKEN ?? null;

  // Collect data sources
  const tf = await collectTerraformOutputs();
  const weaviateState = readWeaviateState();

  const results: ServiceResult[] = [];

  if (tf === null) {
    // Terraform not yet provisioned — show all as not provisioned
    results.push(
      { label: "Vercel API", symbol: "–", detail: "not provisioned" },
      { label: "Vercel Web", symbol: "–", detail: "not provisioned" },
      { label: "Supabase", symbol: "–", detail: "not provisioned" },
      { label: "B2 Bucket", symbol: "–", detail: "not provisioned" },
      { label: "Weaviate", symbol: "–", detail: "not provisioned" },
    );
    printResults(results);
    return;
  }

  const vercelApiProjectId = tfString(tf.vercel_api_project_id);
  const vercelWebProjectId = tfString(tf.vercel_web_project_id);
  const supabaseProjectId = tfString(tf.supabase_project_id);
  const b2BucketName = tfString(tf.b2_bucket_name);

  // Run all async checks in parallel
  const [vercelApiResult, vercelWebResult, supabaseResult] = await Promise.all([
    // Vercel API
    (async (): Promise<ServiceResult> => {
      if (!vercelApiProjectId) {
        return { label: "Vercel API", symbol: "–", detail: "not provisioned" };
      }
      if (!vercelToken) {
        return {
          label: "Vercel API",
          symbol: "–",
          detail: `${vercelApiProjectId} (VERCEL_API_TOKEN not set)`,
        };
      }
      const check = await checkVercelProject(vercelApiProjectId, vercelToken);
      return check.ok
        ? { label: "Vercel API", symbol: "✓", detail: vercelApiProjectId }
        : {
            label: "Vercel API",
            symbol: "✗",
            detail: `${vercelApiProjectId} — ${check.error}`,
          };
    })(),

    // Vercel Web
    (async (): Promise<ServiceResult> => {
      if (!vercelWebProjectId) {
        return { label: "Vercel Web", symbol: "–", detail: "not provisioned" };
      }
      if (!vercelToken) {
        return {
          label: "Vercel Web",
          symbol: "–",
          detail: `${vercelWebProjectId} (VERCEL_API_TOKEN not set)`,
        };
      }
      const check = await checkVercelProject(vercelWebProjectId, vercelToken);
      return check.ok
        ? { label: "Vercel Web", symbol: "✓", detail: vercelWebProjectId }
        : {
            label: "Vercel Web",
            symbol: "✗",
            detail: `${vercelWebProjectId} — ${check.error}`,
          };
    })(),

    // Supabase
    (async (): Promise<ServiceResult> => {
      if (!supabaseProjectId) {
        return { label: "Supabase", symbol: "–", detail: "not provisioned" };
      }
      const supabaseUrl = `https://${supabaseProjectId}.supabase.co`;
      const check = await checkSupabase(supabaseProjectId);
      return check.ok
        ? { label: "Supabase", symbol: "✓", detail: supabaseUrl }
        : {
            label: "Supabase",
            symbol: "✗",
            detail: `${supabaseUrl} — ${check.error}`,
          };
    })(),
  ]);

  results.push(vercelApiResult, vercelWebResult, supabaseResult);

  // B2 Bucket (no health endpoint — report from TF output only)
  if (!b2BucketName) {
    results.push({ label: "B2 Bucket", symbol: "–", detail: "not provisioned" });
  } else {
    results.push({ label: "B2 Bucket", symbol: "✓", detail: b2BucketName });
  }

  // Weaviate
  if (!weaviateState) {
    results.push({ label: "Weaviate", symbol: "–", detail: "not provisioned" });
  } else {
    const check = await checkWeaviate(weaviateState.url);
    if (check.ok) {
      results.push({ label: "Weaviate", symbol: "✓", detail: weaviateState.url });
    } else {
      results.push({
        label: "Weaviate",
        symbol: "✗",
        detail: `${weaviateState.url} — ${check.error}`,
      });
    }
  }

  printResults(results);
}

function printResults(results: ServiceResult[]): void {
  const labelWidth = Math.max(...results.map((r) => r.label.length)) + 2;
  for (const { label, symbol, detail } of results) {
    process.stdout.write(`${pad(label, labelWidth)}${symbol} ${detail}\n`);
  }
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error("Unexpected error:", message);
  process.exit(1);
});
