import { existsSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const STATE_FILE = join(__dirname, "..", ".weaviate-state.json");
const WCD_BASE_URL = "https://api.wcs.weaviate.io/v1";

function validatePathSegment(value: string, name: string): string {
  const sanitized = encodeURIComponent(value);
  if (!sanitized || sanitized.includes("..") || sanitized.includes("/")) {
    throw new Error(`Invalid ${name}: ${value}`);
  }
  return sanitized;
}

interface WeaviateState {
  cluster_id: string;
  url: string;
  api_key: string;
}

interface ClusterCreateResponse {
  cluster_id: string;
  url: string;
  api_key: string;
}

function getEnvVars(): { apiKey: string; clusterName: string } {
  const apiKey = process.env.WCD_API_KEY;
  const clusterName = process.env.CLUSTER_NAME;

  const missing: string[] = [];
  if (!apiKey) missing.push("WCD_API_KEY");
  if (!clusterName) missing.push("CLUSTER_NAME");

  if (missing.length > 0) {
    console.error(
      `Missing required environment variable(s): ${missing.join(", ")}`,
    );
    console.error(
      "Set them before running: WCD_API_KEY=<key> CLUSTER_NAME=<name> bun run weaviate.ts <command>",
    );
    process.exit(1);
  }

  return { apiKey: apiKey!, clusterName: clusterName! };
}

function readState(): WeaviateState | null {
  if (!existsSync(STATE_FILE)) return null;
  try {
    const raw = readFileSync(STATE_FILE, "utf-8");
    return JSON.parse(raw) as WeaviateState;
  } catch {
    return null;
  }
}

function writeState(state: WeaviateState): void {
  const sanitized: WeaviateState = {
    cluster_id: String(state.cluster_id),
    url: String(state.url),
    api_key: String(state.api_key),
  };
  writeFileSync(STATE_FILE, JSON.stringify(sanitized, null, 2), "utf-8");
}

function deleteState(): void {
  if (existsSync(STATE_FILE)) {
    rmSync(STATE_FILE);
  }
}

async function apiRequest<T>(
  method: string,
  path: string,
  apiKey: string,
  body?: unknown,
): Promise<{ ok: boolean; status: number; data: T | null }> {
  const url = `${WCD_BASE_URL}${path}`;
  const headers: Record<string, string> = {
    Authorization: `Bearer ${apiKey}`,
    "Content-Type": "application/json",
  };

  const response = await fetch(url, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (response.status === 204 || response.headers.get("content-length") === "0") {
    return { ok: response.ok, status: response.status, data: null };
  }

  const text = await response.text();
  let data: T | null = null;
  if (text) {
    try {
      data = JSON.parse(text) as T;
    } catch {
      // non-JSON body; leave data as null
    }
  }

  return { ok: response.ok, status: response.status, data };
}

async function commandUp(apiKey: string, clusterName: string): Promise<void> {
  const state = readState();

  if (state?.cluster_id) {
    const check = await apiRequest<unknown>(
      "GET",
      `/clusters/${validatePathSegment(state.cluster_id, "cluster_id")}`,
      apiKey,
    );

    if (check.ok) {
      console.log("Cluster already exists.");
      console.log(`  Cluster ID : ${state.cluster_id}`);
      console.log(`  URL        : ${state.url}`);
      return;
    }

    // State file references a cluster that no longer exists — fall through to create.
    console.log(
      "State file found but cluster no longer exists. Creating a new cluster...",
    );
  }

  console.log(`Creating Weaviate cluster "${clusterName}"...`);

  const create = await apiRequest<ClusterCreateResponse>(
    "POST",
    "/clusters",
    apiKey,
    { name: clusterName, plan: "sandbox" },
  );

  if (!create.ok || !create.data) {
    console.error(
      `Failed to create cluster (HTTP ${create.status}).`,
    );
    if (create.data) {
      console.error("Response:", JSON.stringify(create.data, null, 2));
    }
    process.exit(1);
  }

  const { cluster_id, url, api_key } = create.data;
  writeState({ cluster_id, url, api_key });

  console.log("Cluster created successfully.");
  console.log(`  Cluster ID : ${cluster_id}`);
  console.log(`  URL        : ${url}`);
  console.log(`  State saved: ${STATE_FILE}`);
}

async function commandDown(apiKey: string): Promise<void> {
  const state = readState();

  if (!state?.cluster_id) {
    console.log("No cluster found. Nothing to tear down.");
    return;
  }

  console.log(`Deleting cluster "${state.cluster_id}"...`);

  const del = await apiRequest<unknown>(
    "DELETE",
    `/clusters/${validatePathSegment(state.cluster_id, "cluster_id")}`,
    apiKey,
  );

  if (!del.ok && del.status !== 404) {
    console.error(
      `Failed to delete cluster (HTTP ${del.status}).`,
    );
    if (del.data) {
      console.error("Response:", JSON.stringify(del.data, null, 2));
    }
    process.exit(1);
  }

  deleteState();
  console.log("Cluster deleted and state file removed.");
}

async function commandStatus(apiKey: string): Promise<void> {
  const state = readState();

  if (!state?.cluster_id) {
    console.log("No cluster found. Run `up` first.");
    return;
  }

  const result = await apiRequest<unknown>(
    "GET",
    `/clusters/${validatePathSegment(state.cluster_id, "cluster_id")}`,
    apiKey,
  );

  if (!result.ok) {
    console.error(
      `Failed to fetch cluster status (HTTP ${result.status}).`,
    );
    if (result.data) {
      console.error("Response:", JSON.stringify(result.data, null, 2));
    }
    process.exit(1);
  }

  console.log(JSON.stringify(result.data, null, 2));
}

async function main(): Promise<void> {
  const command = process.argv[2];

  if (!command || !["up", "down", "status"].includes(command)) {
    console.error(
      `Usage: bun run weaviate.ts <command>\n  Commands: up | down | status`,
    );
    process.exit(1);
  }

  const { apiKey, clusterName } = getEnvVars();

  switch (command) {
    case "up":
      await commandUp(apiKey, clusterName);
      break;
    case "down":
      await commandDown(apiKey);
      break;
    case "status":
      await commandStatus(apiKey);
      break;
  }
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error("Unexpected error:", message);
  process.exit(1);
});
