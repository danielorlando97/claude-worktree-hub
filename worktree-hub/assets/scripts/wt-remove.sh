#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"

name="${1:-}"
[[ -n "$name" ]] || {
  echo "Usage: wt-remove.sh <branch-or-folder>  (removes a worktree under worktrees/, never the main checkout)" >&2
  exit 1
}
require_main_repo

target="$wt_root/$(branch_to_folder "$name")"
[[ -d "$target" ]] || { echo "error: no worktree at $target" >&2; exit 1; }

if [[ "$(cd "$target" && pwd)" == "$(git -C "$main_repo" rev-parse --show-toplevel)" ]]; then
  echo "error: refusing to remove the main repository worktree" >&2; exit 1
fi

git -C "$main_repo" worktree remove "$target" --force
echo "removed: $target"
