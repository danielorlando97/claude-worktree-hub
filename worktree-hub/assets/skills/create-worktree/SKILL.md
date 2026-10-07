---
name: create-worktree
description: >-
  Create a new {{REPO}} git worktree under worktrees/ with a new branch from
  {{BASE_BRANCH}}, hard-link local env config, and report the checkout path.
  Use when the user asks to create, open, add, or start a new worktree, branch
  checkout, or parallel task in the hub.
---

# Create worktree

Hub rules: [`AGENTS.md`](../../../AGENTS.md).

## Defaults (unless the user says otherwise)

| Decision | Default |
|----------|---------|
| Base branch | `{{REMOTE}}/{{BASE_BRANCH}}` |
| Branch | **New** branch (never reuse an existing one) |
| Tool | `./scripts/wt-add.sh` only, never `git worktree add` with custom paths |
| Config | Hard links from `{{REPO}}/` via `wt-link-env.sh` (runs inside `wt-add`) |

## Branch name ↔ folder

`feat/api/my-fix` → `worktrees/feat-api-my-fix` (`tr '/' '-'`). To get the branch from a folder use `git -C worktrees/<folder> branch --show-current`; never guess by replacing `-` with `/`.

## Workflow

1. **Pick a branch name** following the team's convention (`feat/…`, `fix/…`, `refactor/…`, optionally scoped by service). Confirm `worktrees/<folder>` does not exist.
2. **Create:**
   ```bash
   ./scripts/wt-add.sh -b fix/short-description {{REMOTE}}/{{BASE_BRANCH}}
   ```
   It fetches, runs `git worktree add -b`, and hard-links `.env`, `*.env` and the extra files from `hub.conf`. Note the printed path.
3. **Verify:**
   ```bash
   ./scripts/wt-status.sh
   git -C worktrees/<folder> status -sb
   ```
4. Work and commit in `worktrees/<folder>/`.

## Exceptions (user must say so explicitly)

```bash
./scripts/wt-add.sh -b fix/hotfix {{REMOTE}}/release/20260101   # different base
./scripts/wt-add.sh feat/already-on-remote                      # resume an existing branch (rare)
```

## Checklist

```
- [ ] Branch name chosen; worktrees/<folder> is free
- [ ] ./scripts/wt-add.sh -b <branch> {{REMOTE}}/{{BASE_BRANCH}}
- [ ] wt-status.sh lists the new entry
- [ ] Tell the user: worktree path, branch name, where to edit
```

## Troubleshooting

| Issue | Action |
|-------|--------|
| `worktree path already exists` | Another branch name, or close the old one (`close-worktree`) |
| Missing env in Docker | `./scripts/wt-link-env.sh --force <folder>` (hard links, not symlinks) |
| Wrong branch checked out | `git -C <worktree> branch --show-current` |

Related: `close-worktree`.
