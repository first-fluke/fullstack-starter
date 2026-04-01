#!/usr/bin/env node

import { execSync } from "node:child_process";
import { existsSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import * as p from "@clack/prompts";

const REPO_URL = "https://github.com/first-fluke/fullstack-starter.git";
const TITLE = "Fullstack Starter";
const DESCRIPTION = "Production-ready fullstack monorepo template";

async function main() {
  console.log();
  p.intro(`${TITLE} - ${DESCRIPTION}`);

  const args = process.argv.slice(2).filter((arg) => !arg.startsWith("-"));
  const flags = process.argv.slice(2).filter((arg) => arg.startsWith("-"));
  const noInstall = flags.includes("--no-install");
  const noGit = flags.includes("--no-git");

  let projectDir = args[0];

  if (!projectDir) {
    const result = await p.text({
      message: "Where should we create your project?",
      placeholder: "./my-app",
      validate: (value) => {
        if (!value) return "Please enter a directory.";
      },
    });

    if (p.isCancel(result)) {
      p.cancel("Cancelled.");
      process.exit(0);
    }

    projectDir = result;
  }

  const targetDir = resolve(process.cwd(), projectDir);
  const projectName = basename(targetDir);

  if (existsSync(targetDir) && readdirSync(targetDir).length > 0) {
    const overwrite = await p.confirm({
      message: `Directory "${projectName}" is not empty. Overwrite?`,
      initialValue: false,
    });

    if (p.isCancel(overwrite) || !overwrite) {
      p.cancel("Cancelled.");
      process.exit(0);
    }

    rmSync(targetDir, { recursive: true, force: true });
  }

  const spinner = p.spinner();
  spinner.start("Cloning template from first-fluke/fullstack-starter");

  try {
    execSync(`git clone --depth 1 ${REPO_URL} "${targetDir}"`, { stdio: "ignore" });
    // Remove .git from cloned template
    rmSync(join(targetDir, ".git"), { recursive: true, force: true });
    spinner.stop("Template cloned.");
  } catch {
    spinner.stop("Failed to clone template.");
    p.log.error("Check your network connection and try again.");
    process.exit(1);
  }

  // Clean up template-specific files
  spinner.start("Cleaning up template files");
  const filesToRemove = ["CHANGELOG.md", "version.txt", ".github", ".agents", ".claude", ".serena"];

  for (const file of filesToRemove) {
    const filePath = join(targetDir, file);
    if (existsSync(filePath)) {
      rmSync(filePath, { recursive: true, force: true });
    }
  }

  writeFileSync(
    join(targetDir, "README.md"),
    `# ${projectName}\n\nCreated with [Fullstack Starter](https://github.com/first-fluke/fullstack-starter).\n`,
  );
  spinner.stop("Cleaned up.");

  if (!noGit) {
    spinner.start("Initializing git repository");
    try {
      execSync("git init", { cwd: targetDir, stdio: "ignore" });
      execSync("git add -A", { cwd: targetDir, stdio: "ignore" });
      execSync('git commit -m "init: scaffold from fullstack-starter"', {
        cwd: targetDir,
        stdio: "ignore",
      });
      spinner.stop("Git initialized.");
    } catch {
      spinner.stop("Git initialization skipped.");
    }
  }

  if (!noInstall) {
    spinner.start("Installing dependencies (this may take a while)");
    try {
      execSync("mise install", { cwd: targetDir, stdio: "ignore", timeout: 300_000 });
      spinner.stop("Dependencies installed.");
    } catch {
      spinner.stop("Auto-install skipped. Run `mise install` manually.");
    }
  }

  const steps = [`cd ${projectDir}`, ...(noInstall ? ["mise install"] : []), "mise dev"];

  p.note(steps.join("\n"), "Next steps");
  p.outro("Happy hacking!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
