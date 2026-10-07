#!/usr/bin/env node

import { cpSync, mkdirSync, existsSync } from "fs";
import { join, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

const args = process.argv.slice(2);
const global = args.includes("--global") || args.includes("-g");

const target = global
  ? join(process.env.HOME, ".claude", "skills", "worktree-hub")
  : join(process.cwd(), ".claude", "skills", "worktree-hub");

const source = resolve(__dirname, "worktree-hub");

if (existsSync(target)) {
  console.log(`⚠️  /worktree-hub already installed at ${target}`);
  console.log("   Run with --force to overwrite.");
  if (!args.includes("--force")) process.exit(0);
}

mkdirSync(target, { recursive: true });
cpSync(source, target, { recursive: true });

const scope = global ? "globally (~/.claude/skills/worktree-hub)" : "locally (.claude/skills/worktree-hub)";
console.log(`✓ /worktree-hub installed ${scope}`);
console.log("");
