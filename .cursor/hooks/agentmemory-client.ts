#!/usr/bin/env bun
import { existsSync, readFileSync } from "node:fs";
import type { IncomingHttpHeaders } from "node:http";
import http from "node:http";
import https from "node:https";
import { homedir } from "node:os";
import { join } from "node:path";

const SUPPORTED = /^0\.(1[12])\./;

function endpointUrl(): string | null {
  if (process.env.OMA_NO_AGENTMEMORY === "1") return null;
  if (process.env.AGENTMEMORY_URL) return process.env.AGENTMEMORY_URL;

  const endpointPath = join(homedir(), ".agentmemory", "endpoint.json");
  if (!existsSync(endpointPath)) return null;

  try {
    const cfg = JSON.parse(readFileSync(endpointPath, "utf-8")) as {
      port?: number;
      url?: string;
    };
    if (typeof cfg.port === "number") return `http://127.0.0.1:${cfg.port}`;
    if (typeof cfg.url === "string" && cfg.url.trim()) return cfg.url;
    return null;
  } catch {
    return null;
  }
}

let reachable: boolean | null = null;

function requestAgentMemory(
  baseUrl: string,
  path: string,
  options: {
    method?: string;
    headers?: Record<string, string>;
    body?: string;
    timeoutMs?: number;
  } = {},
): Promise<{ statusCode: number; headers: IncomingHttpHeaders }> {
  return new Promise((resolve, reject) => {
    const target = new URL(path, baseUrl);
    const client = target.protocol === "https:" ? https : http;
    if (target.protocol !== "http:" && target.protocol !== "https:") {
      reject(new Error(`unsupported protocol ${target.protocol}`));
      return;
    }

    const body = options.body;
    const headers = { ...(options.headers ?? {}) };
    if (body !== undefined && headers["content-length"] === undefined) {
      headers["content-length"] = String(Buffer.byteLength(body));
    }

    const req = client.request(
      target,
      {
        method: options.method ?? "GET",
        headers,
      },
      (res) => {
        res.resume();
        res.on("end", () => {
          resolve({
            statusCode: res.statusCode ?? 0,
            headers: res.headers,
          });
        });
        res.on("error", reject);
      },
    );
    req.setTimeout(options.timeoutMs ?? 500, () => {
      req.destroy(new Error("request timed out"));
    });
    req.on("error", reject);
    if (body !== undefined) req.write(body);
    req.end();
  });
}

export async function isAgentMemoryReachable(): Promise<boolean> {
  if (reachable !== null) return reachable;
  const url = endpointUrl();
  if (!url) {
    reachable = false;
    return reachable;
  }

  try {
    const response = await requestAgentMemory(url, "/agentmemory/health");
    const version = response.headers["x-agentmemory-version"];
    const normalizedVersion = Array.isArray(version) ? version[0] : version;
    if (
      response.statusCode < 200 ||
      response.statusCode >= 300 ||
      !normalizedVersion ||
      !SUPPORTED.test(normalizedVersion)
    ) {
      reachable = false;
      return reachable;
    }
    reachable = true;
    return reachable;
  } catch {
    reachable = false;
    return reachable;
  }
}

export async function observeWithTimeout(payload: object): Promise<boolean> {
  if (!(await isAgentMemoryReachable())) return false;
  const url = endpointUrl();
  if (!url) return false;

  try {
    const response = await requestAgentMemory(url, "/agentmemory/observe", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch {
    return false;
  }
}
