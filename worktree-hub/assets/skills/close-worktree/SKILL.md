---
name: close-worktree
description: >-
  Safely tear down a {{REPO}} git worktree: ensure an open PR exists (create it
  if missing), remove it, optionally delete
  the local branch. Use when the user asks to close, remove, clean up, or cerrar
  a worktree or finished branch checkout.
---

# Close worktree

Hub rules: [`AGENTS.md`](../../../AGENTS.md).

## Inputs

- **Worktree id:** folder under `worktrees/` or branch name. Infer from cwd when inside `worktrees/<name>/`.
- **PR base:** `{{BASE_BRANCH}}` unless the user names another.

## Workflow

### 1. Confirm state

```bash
./scripts/wt-status.sh
./scripts/wt-pr-status.sh <worktree-id>
```

`wt-pr-status.sh` exits **0** if an open PR exists or there is nothing to publish; **2** means the branch has work but no PR (go to step 2); **3** means the PR state cannot be verified (`gh` missing or unauthenticated): check on the remote by hand, and only then close with `--skip-pr`.

### 2. Guarantee a PR

If `pr_url` is `none` and the branch has commits vs `{{BASE_BRANCH}}` or unpushed commits:

1. Follow the repo's own PR conventions if documented (`CONTRIBUTING`, `{{REPO}}/AGENTS.md`, a PR skill under `{{REPO}}/`). Otherwise use the fallback below.
2. Work inside the **worktree directory**. The current branch is the PR branch; do not create another one.
3. Fallback: confirm the diff is one coherent change (`git diff {{REMOTE}}/{{BASE_BRANCH}}...HEAD --stat`), tests pass, push `git push -u {{REMOTE}} HEAD`, then `gh pr create --base {{BASE_BRANCH}} --title "…" --body-file <file>`.
4. Re-run `./scripts/wt-pr-status.sh <id>` until exit 0 with a `pr_url`. Share the URL.

Do **not** run `wt-close.sh` while this step is blocked unless the user explicitly chooses `--skip-pr`.

### 3. User intent

| Situation | Action |
|-----------|--------|
| Uncommitted work to keep | Stop; commit or stash |
| No PR and the user abandons the branch | `wt-close.sh <id> --skip-pr` only with explicit confirmation |
| PR exists | Close once the user is done; merged is typical before `--delete-branch` |

### 4. Close

```bash
./scripts/wt-close.sh <id>                   # keep local branch
./scripts/wt-close.sh <id> --delete-branch   # after merge / user confirms
./scripts/wt-close.sh <id> --force           # discard uncommitted changes (confirm first)
./scripts/wt-close.sh <id> --skip-pr         # no PR required (explicit)
```

### 5. Verify

```bash
./scripts/wt-status.sh
git -C {{REPO}} worktree list
```

## What `wt-close.sh` does

1. PR gate via `wt-pr-status.sh` (unless `--skip-pr`).
2. Refuses the main checkout; aborts if dirty unless `--force`.
3. `git worktree remove --force` + `prune`.
4. Keeps the local branch unless `--delete-branch`.

Hard-linked config inside the worktree is removed with it; the files in `{{REPO}}/` stay.

## Checklist

```
- [ ] wt-status.sh: clean or user-approved --force
- [ ] wt-pr-status.sh: PR exists, or PR created, or --skip-pr confirmed
- [ ] wt-close.sh <id> [flags]
- [ ] wt-status.sh: worktree gone; PR URL shared
```
