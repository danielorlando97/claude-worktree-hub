#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  wt-add.sh <branch>                       Check out an existing branch as a worktree
  wt-add.sh -b <new-branch> [<start>]      Create branch + worktree (start: ref, default origin/<BASE_BRANCH>)

Worktrees land in worktrees/<branch with / replaced by ->. Run from anywhere.
EOF
}

[[ $# -gt 0 ]] || { usage >&2; exit 1; }
require_main_repo

new_branch=""; start_point=""
if [[ "$1" == "-b" ]]; then
  new_branch="${2:?missing new branch name after -b}"
  start_point="${3:-$REMOTE/$BASE_BRANCH}"
  branch="$new_branch"
else
  branch="$1"
fi

target="$wt_root/$(branch_to_folder "$branch")"
[[ ! -e "$target" ]] || { echo "error: worktree path already exists: $target" >&2; exit 1; }

git -C "$main_repo" fetch "$REMOTE" --quiet
mkdir -p "$wt_root"

if [[ -n "$new_branch" ]]; then
  git -C "$main_repo" worktree add -b "$new_branch" "$target" "$start_point"
elif git -C "$main_repo" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$main_repo" worktree add "$target" "$branch"
elif git -C "$main_repo" show-ref --verify --quiet "refs/remotes/$REMOTE/$branch"; then
  git -C "$main_repo" worktree add -b "$branch" "$target" "$REMOTE/$branch"
else
  echo "error: branch not found locally or on $REMOTE: $branch" >&2; exit 1
fi

echo "worktree ready: $target"
link_worktree_envs "$main_repo" "$target" 0
git -C "$target" status -sb
