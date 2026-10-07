#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  wt-link-env.sh [--force] <worktree-path|branch|folder>
  wt-link-env.sh [--force] --all

Hard-link local config (.env, *.env, plus EXTRA_LINK_NAMES from hub.conf) from the
main checkout into worktrees. Hard links, not symlinks: Docker bind mounts cannot
follow symlinks out of the mounted tree. Symlinks are upgraded automatically.
Re-run after adding new env files to the main checkout.
EOF
}

force=0; args=()
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -h | --help) usage; exit 0 ;;
    *) args+=("$arg") ;;
  esac
done
[[ ${#args[@]} -gt 0 ]] || { usage >&2; exit 1; }
require_main_repo

if [[ "${args[0]}" == "--all" ]]; then
  found=0
  for dir in "$wt_root"/*; do
    [[ -d "$dir" && -e "$dir/.git" ]] || continue
    link_worktree_envs "$main_repo" "$dir" "$force"; found=1
  done
  [[ "$found" -eq 1 ]] || echo "no worktrees under $wt_root"
  exit 0
fi

wt="$(resolve_worktree "${args[0]}")" || { echo "error: worktree not found: ${args[0]}" >&2; exit 1; }
link_worktree_envs "$main_repo" "$wt" "$force"
