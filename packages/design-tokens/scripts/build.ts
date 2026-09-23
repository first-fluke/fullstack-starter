import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

function runScript(scriptPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn("node", ["--import=tsx", scriptPath], {
      cwd: dirname(__dirname),
      stdio: "inherit",
    });

    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Script ${scriptPath} exited with code ${code}`));
      }
    });

    proc.on("error", reject);
  });
}

async function main(): Promise<void> {
  console.log("🚀 Starting design tokens build...\n");

  const startTime = Date.now();

  try {
    await runScript(resolve(__dirname, "build-css.ts"));
    await runScript(resolve(__dirname, "build-forui-theme.ts"));

    const duration = Date.now() - startTime;
    console.log(`\n✨ Build completed in ${duration}ms`);
  } catch (error) {
    console.error("\n❌ Build failed:", error);
    process.exit(1);
  }
}

void main();
