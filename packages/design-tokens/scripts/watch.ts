import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { watch } from "chokidar";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = dirname(__dirname);
const TOKENS_FILE = resolve(ROOT, "src/tokens.ts");

let isBuilding = false;
let pendingBuild = false;

function runBuild(): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn("node", ["--import=tsx", "scripts/build.ts"], {
      cwd: ROOT,
      stdio: "inherit",
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Build exited with code ${code}`));
      }
    });

    proc.on("error", reject);
  });
}

async function debouncedBuild(): Promise<void> {
  if (isBuilding) {
    pendingBuild = true;
    return;
  }

  isBuilding = true;

  try {
    await runBuild();
  } catch (error) {
    console.error("Build error:", error);
  } finally {
    isBuilding = false;

    if (pendingBuild) {
      pendingBuild = false;
      await debouncedBuild();
    }
  }
}

function main(): void {
  console.log("👀 Watching for token changes...");
  console.log(`   File: ${TOKENS_FILE}\n`);

  const watcher = watch(TOKENS_FILE, {
    persistent: true,
    ignoreInitial: true,
  });

  watcher.on("change", (path) => {
    console.log(`\n📝 File changed: ${path}`);
    void debouncedBuild();
  });

  watcher.on("error", (error) => {
    console.error("Watcher error:", error);
  });

  console.log("🔨 Running initial build...\n");
  void debouncedBuild();
}

main();
