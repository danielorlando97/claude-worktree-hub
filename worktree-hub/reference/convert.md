# convert — existing checkout → hub

Input: `[repo-path]` (default: git toplevel of cwd). Result: `<parent>/<REPO>-hub/<REPO>/` holding the same checkout, plus scaffold.

This **moves** the user's working directory. Be conservative; every irreversible step is gated.

## 1. Inspect (read-only)

```bash
git -C "$SRC" rev-parse --show-toplevel          # must equal $SRC; if $SRC is itself a linked worktree, stop and ask which is the main one
git -C "$SRC" status -sb
git -C "$SRC" worktree list --porcelain          # existing worktrees (absolute paths inside git metadata)
git -C "$SRC" remote -v
git -C "$SRC" symbolic-ref --short refs/remotes/origin/HEAD
docker ps --format '{{.Names}}\t{{.Mounts}}' | grep "$SRC"   # containers bind-mounting this path
lsof +D "$SRC" 2>/dev/null | head                           # open editors/servers (skip if slow)
```

Report to the user: dirty files (fine, they travel with the move), existing worktrees and where they live, running containers/processes using the path.

## 2. Plan and confirm (one message)

State exactly:
- `mv "$SRC" "$HUB/$REPO"` (same filesystem → instant, nothing copied; if `$HUB` would be on another volume, hard links for env files break, so refuse and explain).
- Existing worktrees outside `worktrees/` will be **moved** into `$HUB/worktrees/<branch-with-dashes>` with `git worktree move`, or left alone if the user prefers.
- Anything running from `$SRC` must be stopped first; IDEs must be reopened on `$HUB`.

Wait for an explicit yes. If containers or processes use the path, stop and ask the user to shut them down.

## 3. Execute

```bash
mkdir -p "$HUB"
mv "$SRC" "$HUB/$REPO"
git -C "$HUB/$REPO" worktree repair              # fixes gitdir pointers of linked worktrees that did not move
<skill-dir>/bin/hub-scaffold.sh "$HUB" "$REPO" "$BASE_BRANCH" "$REMOTE"
```

Then, for each pre-existing linked worktree (from step 1) not already under `$HUB/worktrees/`:

```bash
git -C "$HUB/$REPO" worktree move <old-path> "$HUB/worktrees/$(printf '%s' <branch> | tr '/' '-')"
```

Skip detached or locked ones and list them. After moves run `git -C "$HUB/$REPO" worktree list` and `"$HUB/scripts/wt-link-env.sh" --all` so env files become hard links to the main checkout.

If `$SRC` was a symlink target, an IDE project, or referenced by absolute path in dotfiles/compose files, say so; leave a symlink `ln -s "$HUB/$REPO" "$SRC"` only if the user asks.

## 4. Adapt project specifics

- If the repo already has `AGENTS.md`/`CLAUDE.md`, leave them; the hub-level ones are separate and point into them.

## 5. Verify

Run the `check` procedure (reference/check.md). Confirm `git -C "$HUB/$REPO" status -sb` matches the pre-move status and that `wt-status.sh` lists every worktree.

## Rollback

Before moving, record `$SRC` and the old worktree paths. To undo: `mv "$HUB/$REPO" "$SRC"`, `git -C "$SRC" worktree repair`, move worktrees back, then remove the scaffolded files from `$HUB`.
