import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");
const SOURCE_DIR = join(ROOT, "source");
const WEB_OUTPUT_DIR = resolve(ROOT, "../../apps/web/src/config/messages");
const MOBILE_OUTPUT_DIR = resolve(ROOT, "../../apps/mobile/lib/i18n/messages");

interface ArbFile {
  [key: string]: string | object;
}

interface NestedJson {
  [key: string]: string | NestedJson;
}

function parseArgs(): { target: "all" | "web" | "mobile" } {
  const args = process.argv.slice(2);
  const targetIndex = args.indexOf("--target");
  if (targetIndex !== -1 && args[targetIndex + 1]) {
    const target = args[targetIndex + 1];
    if (target === "web" || target === "mobile") {
      return { target };
    }
  }
  return { target: "all" };
}

function readArbFiles(): Map<string, ArbFile> {
  const files = new Map<string, ArbFile>();
  const arbFiles = readdirSync(SOURCE_DIR).filter((f) => f.endsWith(".arb"));

  for (const file of arbFiles) {
    const content = readFileSync(join(SOURCE_DIR, file), "utf-8");
    const locale = file.replace(".arb", "");
    files.set(locale, JSON.parse(content));
  }

  return files;
}

const COMMON_KEYS = ["loading", "error", "save", "cancel", "confirm", "delete", "retry"];

function isArbMetadataKey(key: string): boolean {
  return key.startsWith("@@") || key.startsWith("@");
}

function arbToNestedJson(arb: ArbFile): NestedJson {
  const result: NestedJson = {};

  for (const [key, value] of Object.entries(arb)) {
    if (isArbMetadataKey(key)) {
      continue;
    }

    if (COMMON_KEYS.includes(key)) {
      if (!result.common) {
        result.common = {};
      }
      (result.common as NestedJson)[key] = value as string;
    } else if (key === "appTitle") {
      result.title = value as string;
    } else {
      result[key] = value as string;
    }
  }

  return result;
}

function arbToMobileArb(arb: ArbFile, locale: string): ArbFile {
  const result: ArbFile = { "@@locale": locale };

  for (const [key, value] of Object.entries(arb)) {
    if (key === "@@locale") continue;
    result[key] = value;
  }

  return result;
}

function ensureDir(dir: string): void {
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
}

function cleanDir(dir: string): void {
  if (existsSync(dir)) {
    rmSync(dir, { recursive: true, force: true });
  }
  mkdirSync(dir, { recursive: true });
}

function buildWeb(arbFiles: Map<string, ArbFile>): void {
  console.log("Building web i18n files...");
  cleanDir(WEB_OUTPUT_DIR);

  for (const [locale, arb] of arbFiles) {
    const nested = arbToNestedJson(arb);
    const outputPath = join(WEB_OUTPUT_DIR, `${locale}.json`);
    writeFileSync(outputPath, `${JSON.stringify(nested, null, 2)}\n`);
    console.log(`  Created: ${outputPath}`);
  }
}

function buildMobile(arbFiles: Map<string, ArbFile>): void {
  console.log("Building mobile i18n files...");
  ensureDir(MOBILE_OUTPUT_DIR);

  for (const [locale, arb] of arbFiles) {
    const mobileArb = arbToMobileArb(arb, locale);
    const outputPath = join(MOBILE_OUTPUT_DIR, `app_${locale}.arb`);
    writeFileSync(outputPath, `${JSON.stringify(mobileArb, null, 2)}\n`);
    console.log(`  Created: ${outputPath}`);
  }
}

function main(): void {
  const { target } = parseArgs();
  console.log(`i18n build started (target: ${target})`);

  const arbFiles = readArbFiles();
  console.log(`Found ${arbFiles.size} locale(s): ${[...arbFiles.keys()].join(", ")}`);

  if (target === "all" || target === "web") {
    buildWeb(arbFiles);
  }

  if (target === "all" || target === "mobile") {
    buildMobile(arbFiles);
  }

  console.log("i18n build completed!");
}

main();
