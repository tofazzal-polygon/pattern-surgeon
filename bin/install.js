#!/usr/bin/env node
"use strict";

const fs   = require("fs");
const path = require("path");
const os   = require("os");

const SKILL_SRC  = path.join(__dirname, "..", "skills", "pattern-surgeon");
const SKILL_NAME = "pattern-surgeon";

// ── argument parsing ──────────────────────────────────────────────────────
const args       = process.argv.slice(2);
const isProject  = args.includes("--project") || args.includes("-p");
const isPost     = args.includes("--postinstall");   // called by npm postinstall
const isUninstall= args.includes("--uninstall") || args.includes("remove");
const isHelp     = args.includes("--help") || args.includes("-h");

// During npm global install `npm_config_global` is set to "true"
const isGlobal   = process.env.npm_config_global === "true";

// ── target directory ──────────────────────────────────────────────────────
function targetDir() {
  if (isProject) return path.join(process.cwd(), ".claude", "skills", SKILL_NAME);
  if (isGlobal || !isPost)  return path.join(os.homedir(), ".claude", "skills", SKILL_NAME);
  // local npm install (postinstall, not global) → project-local
  return path.join(process.cwd(), ".claude", "skills", SKILL_NAME);
}

// ── helpers ───────────────────────────────────────────────────────────────
function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

function removeDir(dir) {
  if (fs.existsSync(dir)) fs.rmSync(dir, { recursive: true, force: true });
}

function bold(s)  { return `\x1b[1m${s}\x1b[0m`; }
function green(s) { return `\x1b[32m${s}\x1b[0m`; }
function cyan(s)  { return `\x1b[36m${s}\x1b[0m`; }
function dim(s)   { return `\x1b[2m${s}\x1b[0m`; }

// ── commands ──────────────────────────────────────────────────────────────
if (isHelp) {
  console.log(`
${bold("pattern-surgeon")} — design-pattern skill for Claude Code

${bold("Usage")}
  npx @nuhin13/pattern-surgeon            Install globally (~/.claude/skills/)
  npx @nuhin13/pattern-surgeon --project  Install into current project (.claude/skills/)
  npx @nuhin13/pattern-surgeon remove     Uninstall from global location
  npx @nuhin13/pattern-surgeon --help     Show this help

${bold("After install")}
  Restart Claude Code (or start a new session) and talk to Claude:
  ${cyan('"What pattern fits src/checkout.ts?"')}
  ${cyan('"Refactor this pricing logic — it has a big switch"')}
  ${cyan('"Compare Strategy vs Factory for services/OrderService.kt"')}

${bold("Supported languages")}
  TS/JS · Python · Java · C# · PHP · Kotlin/Android · Dart/Flutter · Swift

${bold("Plugin install (Claude Code native)")}
  In Claude Code type:
  ${cyan("/plugin marketplace add nuhin13/pattern-surgeon")}
  ${cyan("/plugin install pattern-surgeon")}
`);
  process.exit(0);
}

if (isUninstall) {
  const dest = targetDir();
  removeDir(dest);
  console.log(`${green("✓")} pattern-surgeon removed from ${dim(dest)}`);
  process.exit(0);
}

// ── install ───────────────────────────────────────────────────────────────
const dest = targetDir();

try {
  copyDir(SKILL_SRC, dest);
} catch (err) {
  // During postinstall, failing silently is better than blocking npm install
  if (isPost) process.exit(0);
  console.error(`\x1b[31m✗ Install failed:\x1b[0m ${err.message}`);
  process.exit(1);
}

if (!isPost || process.env.PATTERN_SURGEON_VERBOSE) {
  const scope = isProject ? "project" : "global";
  console.log(`
${green("✓")} ${bold("pattern-surgeon")} installed (${scope})
  ${dim("→")} ${dest}

${bold("Use it:")} open Claude Code and say
  ${cyan('"What pattern fits src/checkout.ts?"')}
  ${cyan('"Refactor this pricing logic"')}
  ${cyan('"Implement X with the right pattern"')}

${bold("Uninstall:")} ${dim("npx @nuhin13/pattern-surgeon remove")}
`);
}
