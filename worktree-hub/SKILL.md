---
name: worktree-hub
description: Initialize a new project, or convert an existing git checkout, into a "worktree hub" — a workspace root holding the main repo checkout, a `worktrees/` folder for parallel branches, helper `scripts/wt-*.sh`, and agent skills to create and close worktrees. Use when the user wants to set up a worktree hub, restructure a repo for parallel work, work on several branches in parallel with agents, or audit an existing hub. Commands: init, convert, check, extend.
argument-hint: "[init|convert|check|extend] [args]"
---

# worktree-hub

Builds this layout:

```text
<hub>/                      ← workspace root (open this in the IDE)
├── AGENTS.md  CLAUDE.md    ← hub rules for agents
├── <repo>/                 ← main checkout (source of truth for .env files)
├── worktrees/              ← extra worktrees only
├── scripts/                ← hub.conf, wt-lib.sh, wt-add/close/remove/status/pr-status/link-env
└── .claude/skills/         ← create-worktree, close-worktree  (other tools: --also-link)
```

## Commands

| Command | Purpose | Reference |
|---------|---------|-----------|
| `init <remote-url> [hub-dir]` | New hub: clone the repo into it and scaffold everything | [reference/init.md](reference/init.md) |
| `convert [repo-path]` | Turn an existing checkout (and its worktrees) into a hub, moving it in | [reference/convert.md](reference/convert.md) |
| `check [hub-dir]` | Audit a hub against the layout; report drift, fix on request | [reference/check.md](reference/check.md) |
| `extend [hub-dir]` | Adjust: extra shared files, other tools' skill dirs, PR conventions, relocatable hub | [reference/extend.md](reference/extend.md) |

Route on the first word of the arguments, then **read the matching reference file before acting**. No arguments: if cwd is inside a git repo that is not a hub, suggest `convert`; if it is an empty directory, suggest `init`; if `scripts/hub.conf` exists, suggest `check`. Ask only when that is ambiguous.

## Parameters (collected by every command)

| Name | Meaning | Default |
|------|---------|---------|
| `REPO` | Folder name of the main checkout inside the hub | basename of the remote / repo |
| `BASE_BRANCH` | Branch new worktrees fork from and PRs target | `origin/HEAD` of the repo; ask if undetectable |
| `REMOTE` | Git remote name | `origin` |
| `HUB` | Hub directory | `<parent>/<REPO>-hub` for convert, given path for init |

Detect defaults from the repo (`git symbolic-ref refs/remotes/origin/HEAD`) instead of asking. Confirm all four in one short message before touching disk.

## Mechanical work lives in `bin/hub-scaffold.sh`

`bin/hub-scaffold.sh [--force] [--also-link <dirs>] <HUB> <REPO> <BASE_BRANCH> [REMOTE]` copies `assets/` into the hub, renders the `{{REPO}}`, `{{BASE_BRANCH}}`, `{{REMOTE}}`, `{{HUB}}` placeholders, makes scripts executable, and creates `worktrees/`. `--also-link .agents,.cursor` symlinks other tools' skill dirs to `.claude/skills`. It never overwrites an existing file (prints `skip:`); pass `--force` to replace. Do the git parts (clone / move) yourself; do not re-type the templates by hand.

## Rules

- Never delete or overwrite the user's repo, `.env` files or existing worktrees. Moving is the only destructive-adjacent step and is gated in `convert`.
- Worktrees are created only through `scripts/wt-add.sh` (it enforces the `worktrees/<branch-with-dashes>` convention and hard-links env files).
- Hard links, not symlinks, for shared local config (Docker bind mounts can't follow symlinks out of the mount).
- Finish by running `check` logic (read-only) and report what passed. Say plainly what was skipped.
