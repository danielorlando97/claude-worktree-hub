# init — new hub from a remote

Input: `<remote-url> [hub-dir]`. Hub dir defaults to `./<repo>-hub` (or cwd if it is empty and the user said "here").

## Steps

1. **Resolve parameters** (see SKILL.md). `REPO` = remote basename without `.git`.
2. **Preflight:** `HUB` must not exist or must be empty. `git` available. Remote reachable: `git ls-remote <url> HEAD`.
3. **Clone** the main checkout into the hub:
   ```bash
   mkdir -p "$HUB" && git clone <url> "$HUB/$REPO"
   ```
4. **BASE_BRANCH:** `git -C "$HUB/$REPO" symbolic-ref --short refs/remotes/origin/HEAD` → strip `origin/`. If unset, run `git -C "$HUB/$REPO" remote set-head origin -a` and retry; if still unknown, ask the user. Use the user's branch if they named one.
5. **Scaffold:**
   ```bash
   <skill-dir>/bin/hub-scaffold.sh "$HUB" "$REPO" "$BASE_BRANCH" origin
   ```
6. **Git hygiene:** the hub root is *not* a git repo (the repo lives in `$REPO/`). Do not `git init` it unless the user asks. If they want the hub tracked (scripts + skills), offer a separate repo, not the main one.
7. **Smoke test** (no side effects on the remote):
   ```bash
   "$HUB/scripts/wt-add.sh" -b chore/hub-smoke "origin/$BASE_BRANCH"
   "$HUB/scripts/wt-status.sh"
   "$HUB/scripts/wt-remove.sh" chore/hub-smoke
   git -C "$HUB/$REPO" branch -D chore/hub-smoke
   ```
   Skip this and say so if the clone is huge or the user declines.
8. **Next step:** tell the user to open `$HUB` as the IDE workspace root, and offer `extend` (extra shared files, other tools' skill dirs).

## Report

Print the tree (depth 2), the resolved parameters, and the three commands they will use most:
`wt-add.sh -b <branch> origin/<BASE_BRANCH>`, `wt-status.sh`, `wt-close.sh <id>`.
