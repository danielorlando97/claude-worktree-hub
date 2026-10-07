# check — audit a hub

Read-only by default. Input: `[hub-dir]` (default: nearest ancestor of cwd containing `scripts/hub.conf`, else cwd).

## Checklist

Run each, report pass/fail in one table.

| # | Check | How |
|---|-------|-----|
| 1 | `scripts/hub.conf` exists with `MAIN_REPO`, `BASE_BRANCH`, `REMOTE` | `source` it |
| 2 | Main checkout is a git repo | `[ -d "$HUB/$MAIN_REPO/.git" ]` |
| 3 | `worktrees/` exists | `[ -d "$HUB/worktrees" ]` |
| 4 | Every script from `assets/scripts/` is present and executable | `diff -q` against template after rendering placeholders; report drift, don't overwrite |
| 5 | `AGENTS.md` and `CLAUDE.md` at the root, both mention `wt-add.sh` | grep |
| 6 | `create-worktree` and `close-worktree` exist under `.claude/skills/`; any extra tool dirs resolve to it | `ls`, `readlink` |
| 7 | All linked worktrees live under `worktrees/` | `git worktree list` |
| 8 | Env files in worktrees are hard links of the main ones (same inode) | `wt-link-env.sh --all` prints skips; or `stat -f %i` |
| 9 | Remote `BASE_BRANCH` exists | `git ls-remote --heads $REMOTE $BASE_BRANCH` |
| 10 | No broken worktrees | `git worktree list` for `prunable`; suggest `git worktree prune` |

## Fixing

Offer, never auto-apply:
- Missing/outdated file → `bin/hub-scaffold.sh <HUB> <REPO> <BASE> --force` only for the named files (copy the single asset manually if the user only wants one).
- Drifted script with local edits → show `diff`, ask which side wins.
- Stray worktree outside `worktrees/` → `git worktree move`.
