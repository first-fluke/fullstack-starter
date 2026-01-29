#!/usr/bin/env node
/**
 * Serena Memory Web Dashboard Server
 *
 * Watches .serena/memories/ for file changes using chokidar,
 * then pushes updates to connected browsers via WebSocket.
 *
 * Usage:
 *   node scripts/dashboard-web/server.js [project-path]
 *   MEMORIES_DIR=/path/to/.serena/memories node scripts/dashboard-web/server.js
 *   → http://localhost:9847
 *
 * Examples:
 *   node scripts/dashboard-web/server.js /path/to/pic2cook
 *   MEMORIES_DIR=/path/to/pic2cook/.serena/memories node scripts/dashboard-web/server.js
 */

const http = require("http");
const fs = require("fs");
const path = require("path");

let chokidar;
let WebSocketServer;

try {
  chokidar = require("chokidar");
} catch {
  console.error(
    "Missing dependency: chokidar\nRun: bun install chokidar ws"
  );
  process.exit(1);
}

try {
  ({ WebSocketServer } = require("ws"));
} catch {
  console.error("Missing dependency: ws\nRun: bun install chokidar ws");
  process.exit(1);
}

const PORT = process.env.DASHBOARD_PORT || 9847;

// Determine memories directory:
// 1. MEMORIES_DIR env var (direct path to memories)
// 2. CLI argument (project root path)
// 3. Default: this project's .serena/memories
function resolveMemoriesDir() {
  // Option 1: Direct MEMORIES_DIR environment variable
  if (process.env.MEMORIES_DIR) {
    return process.env.MEMORIES_DIR;
  }

  // Option 2: CLI argument as project root
  const cliArg = process.argv[2];
  if (cliArg) {
    const projectPath = path.resolve(cliArg);
    return path.join(projectPath, ".serena", "memories");
  }

  // Option 3: Default to this project
  const PROJECT_ROOT = path.resolve(__dirname, "../..");
  return path.join(PROJECT_ROOT, ".serena", "memories");
}

const MEMORIES_DIR = resolveMemoriesDir();
const PUBLIC_DIR = path.join(__dirname, "public");

// Ensure memories dir exists
if (!fs.existsSync(MEMORIES_DIR)) {
  fs.mkdirSync(MEMORIES_DIR, { recursive: true });
}

// --- File parsing helpers ---

function readFileSafe(filePath) {
  try {
    return fs.readFileSync(filePath, "utf-8");
  } catch {
    return "";
  }
}

function findSessionFile() {
  // Look for session files in priority order
  const patterns = [
    "orchestrator-session.md",
    /^session-.*\.md$/,
  ];

  try {
    const files = fs.readdirSync(MEMORIES_DIR);

    // First try exact match
    if (files.includes("orchestrator-session.md")) {
      return path.join(MEMORIES_DIR, "orchestrator-session.md");
    }

    // Then try session-*.md pattern (most recently modified)
    const sessionFiles = files
      .filter((f) => /^session-.*\.md$/.test(f))
      .map((f) => ({
        name: f,
        mtime: fs.statSync(path.join(MEMORIES_DIR, f)).mtimeMs,
      }))
      .sort((a, b) => b.mtime - a.mtime);

    if (sessionFiles.length > 0) {
      return path.join(MEMORIES_DIR, sessionFiles[0].name);
    }
  } catch {
    // ignore
  }
  return null;
}

function parseSessionInfo() {
  const sessionFile = findSessionFile();
  if (!sessionFile) return { id: "N/A", status: "UNKNOWN" };

  const content = readFileSafe(sessionFile);
  if (!content) return { id: "N/A", status: "UNKNOWN" };

  // Extract session ID from various formats
  let id =
    (content.match(/session-id:\s*(.+)/i) || [])[1] ||
    (content.match(/# Session:\s*(.+)/i) || [])[1] ||
    (content.match(/(session-\d{8}-\d{6})/)?.[1]) ||
    path.basename(sessionFile, ".md") ||
    "N/A";

  // Determine status from content
  let status = "UNKNOWN";
  if (/IN PROGRESS|RUNNING|## Active|\[IN PROGRESS\]/i.test(content)) {
    status = "RUNNING";
  } else if (/COMPLETED|DONE|## Completed|\[COMPLETED\]/i.test(content)) {
    status = "COMPLETED";
  } else if (/FAILED|ERROR|## Failed|\[FAILED\]/i.test(content)) {
    status = "FAILED";
  } else if (/Step \d+:.*\[/i.test(content)) {
    // Has step markers, likely running
    status = "RUNNING";
  }

  return { id: id.trim(), status, file: path.basename(sessionFile) };
}

function parseTaskBoard() {
  const content = readFileSafe(path.join(MEMORIES_DIR, "task-board.md"));
  if (!content) return [];

  const agents = [];
  const lines = content.split("\n");
  for (const line of lines) {
    if (!line.startsWith("|") || /^\|\s*-+/.test(line)) continue;
    const cols = line.split("|").map((c) => c.trim()).filter(Boolean);
    if (cols.length < 2) continue;
    // Skip header
    if (/^agent$/i.test(cols[0])) continue;

    agents.push({
      agent: cols[0] || "",
      status: cols[1] || "pending",
      task: cols[2] || "",
    });
  }
  return agents;
}

function getAgentTurn(agent) {
  try {
    const files = fs.readdirSync(MEMORIES_DIR)
      .filter((f) => f.startsWith(`progress-${agent}`) && f.endsWith(".md"))
      .sort()
      .reverse();
    if (files.length === 0) return null;
    const content = readFileSafe(path.join(MEMORIES_DIR, files[0]));
    const match = content.match(/turn[:\s]*(\d+)/i);
    return match ? parseInt(match[1], 10) : null;
  } catch {
    return null;
  }
}

function getLatestActivity() {
  try {
    // Get all .md files, sorted by modification time
    const files = fs.readdirSync(MEMORIES_DIR)
      .filter((f) => f.endsWith(".md") && f !== ".gitkeep")
      .map((f) => ({
        name: f,
        mtime: fs.statSync(path.join(MEMORIES_DIR, f)).mtimeMs,
      }))
      .sort((a, b) => b.mtime - a.mtime)
      .slice(0, 10);

    return files.map((f) => {
      // Extract agent/topic name from filename
      const name = f.name
        .replace(/^(progress|result|session|debug|task)-?/, "")
        .replace(/[-_]agent/, "")
        .replace(/[-_]completion/, "")
        .replace(/\.md$/, "")
        .replace(/[-_]/g, " ")
        .trim() || f.name.replace(/\.md$/, "");

      const content = readFileSafe(path.join(MEMORIES_DIR, f.name));

      // Find meaningful last line (heading, list item, or status)
      const lines = content.split("\n")
        .map((l) => l.trim())
        .filter((l) => l && !l.startsWith("---") && l.length > 3);

      // Look for status markers or last meaningful content
      let message = "";
      for (let i = lines.length - 1; i >= 0; i--) {
        const line = lines[i];
        if (/^\*\*|^#+|^-|^\d+\.|Status|Result|Action|Step/i.test(line)) {
          message = line.replace(/^[#*\-\d.]+\s*/, "").replace(/\*\*/g, "").trim();
          if (message.length > 5) break;
        }
      }

      // Truncate long messages
      if (message.length > 80) {
        message = message.substring(0, 77) + "...";
      }

      return { agent: name, message, file: f.name };
    }).filter((a) => a.message);
  } catch {
    return [];
  }
}

function discoverAgentsFromFiles() {
  const agents = [];
  const seen = new Set();

  try {
    const files = fs.readdirSync(MEMORIES_DIR)
      .filter((f) => f.endsWith(".md") && f !== ".gitkeep")
      .map((f) => ({
        name: f,
        mtime: fs.statSync(path.join(MEMORIES_DIR, f)).mtimeMs,
      }))
      .sort((a, b) => b.mtime - a.mtime);

    for (const f of files) {
      const content = readFileSafe(path.join(MEMORIES_DIR, f.name));

      // Look for agent markers in content
      const agentMatch = content.match(/\*\*Agent\*\*:\s*(.+)/i) ||
                         content.match(/Agent:\s*(.+)/i) ||
                         content.match(/^#+\s*(.+?)\s*Agent/im);

      let agentName = null;
      if (agentMatch) {
        agentName = agentMatch[1].trim();
      } else if (/_agent|agent_|-agent/i.test(f.name)) {
        // Extract from filename
        agentName = f.name
          .replace(/\.md$/, "")
          .replace(/[-_]completion|[-_]progress|[-_]result/gi, "")
          .replace(/[-_]/g, " ")
          .trim();
      }

      if (agentName && !seen.has(agentName.toLowerCase())) {
        seen.add(agentName.toLowerCase());

        // Determine status from content
        let status = "unknown";
        if (/\[COMPLETED\]|## Completed|## Results/i.test(content)) {
          status = "completed";
        } else if (/\[IN PROGRESS\]|## Progress|IN PROGRESS/i.test(content)) {
          status = "running";
        } else if (/\[FAILED\]|## Failed|ERROR/i.test(content)) {
          status = "failed";
        }

        // Extract task summary
        const taskMatch = content.match(/## Task\s*\n+(.+)/i) ||
                          content.match(/\*\*Task\*\*:\s*(.+)/i);
        const task = taskMatch ? taskMatch[1].trim().substring(0, 60) : "";

        agents.push({
          agent: agentName,
          status,
          task,
          file: f.name,
          turn: getAgentTurn(agentName),
        });
      }
    }
  } catch {
    // ignore
  }

  return agents;
}

function buildFullState() {
  const session = parseSessionInfo();
  const taskBoard = parseTaskBoard();

  // Enrich with turn info
  let agents = taskBoard.map((a) => ({
    ...a,
    turn: getAgentTurn(a.agent),
  }));

  // If no task board, discover agents from memory files
  if (agents.length === 0) {
    agents = discoverAgentsFromFiles();
  }

  // If still no agents, try progress files
  if (agents.length === 0) {
    try {
      const progressFiles = fs.readdirSync(MEMORIES_DIR)
        .filter((f) => f.startsWith("progress-") && f.endsWith(".md"));
      for (const f of progressFiles) {
        const agent = f.replace(/^progress-/, "").replace(/\.md$/, "");
        agents.push({
          agent,
          status: "running",
          task: "",
          turn: getAgentTurn(agent),
        });
      }
    } catch {
      // ignore
    }
  }

  const activity = getLatestActivity();

  return {
    session,
    agents,
    activity,
    memoriesDir: MEMORIES_DIR,
    updatedAt: new Date().toISOString()
  };
}

// --- HTTP server ---

const MIME_TYPES = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

const httpServer = http.createServer((req, res) => {
  // API endpoint for current state
  if (req.url === "/api/state") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(buildFullState()));
    return;
  }

  // Serve static files
  let filePath = req.url === "/" ? "/index.html" : req.url;
  filePath = path.join(PUBLIC_DIR, filePath);

  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || "application/octet-stream";

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end("Not Found");
      return;
    }
    res.writeHead(200, { "Content-Type": contentType });
    res.end(data);
  });
});

// --- WebSocket server ---

const wss = new WebSocketServer({ server: httpServer });

function broadcast(data) {
  const msg = JSON.stringify(data);
  for (const client of wss.clients) {
    if (client.readyState === 1) {
      client.send(msg);
    }
  }
}

wss.on("connection", (ws) => {
  // Send full state on connect
  ws.send(JSON.stringify({ type: "full", data: buildFullState() }));

  // Clean up dead connections
  ws.on("error", () => {
    ws.terminate();
  });
});

// --- File watcher ---

let debounceTimer = null;

const watcher = chokidar.watch(MEMORIES_DIR, {
  persistent: true,
  ignoreInitial: true,
  awaitWriteFinish: { stabilityThreshold: 200, pollInterval: 50 },
});

watcher.on("all", (event, filePath) => {
  // Debounce: collapse rapid changes into one update
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    const state = buildFullState();
    broadcast({
      type: "update",
      event,
      file: path.basename(filePath),
      data: state,
    });
  }, 100);
});

// --- Graceful shutdown ---

function shutdown() {
  console.log("\nShutting down...");

  // Close file watcher
  watcher.close().then(() => {
    console.log("  File watcher closed");
  }).catch(() => {});

  // Close all WebSocket connections
  for (const client of wss.clients) {
    client.terminate();
  }

  // Close WebSocket server
  wss.close(() => {
    console.log("  WebSocket server closed");

    // Close HTTP server
    httpServer.close(() => {
      console.log("  HTTP server closed");
      process.exit(0);
    });
  });

  // Force exit after 3 seconds if graceful shutdown hangs
  setTimeout(() => {
    console.error("  Forced exit after timeout");
    process.exit(1);
  }, 3000).unref();
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

// --- Start ---

httpServer.listen(PORT, () => {
  console.log(`Serena Memory Dashboard`);
  console.log(`  Web UI:  http://localhost:${PORT}`);
  console.log(`  Watching: ${MEMORIES_DIR}`);
  console.log(`  Press Ctrl+C to stop`);
});
