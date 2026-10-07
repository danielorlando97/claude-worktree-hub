#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"
require_main_repo

while IFS= read -r line; do
  path="${line%% *}"
  rest="${line#* }"
  branch_info="${rest#* }"

  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "$path"
  echo "  $branch_info"
  echo "────────────────────────────────────────────────────────────"

  [[ -d "$path" ]] || { echo "  (missing directory)"; continue; }

  git -C "$path" status -sb || true
  if ! git -C "$path" diff --quiet 2>/dev/null; then
    echo ""; echo "  unstaged:"
    git -C "$path" diff --stat | sed 's/^/    /'
  fi
  if ! git -C "$path" diff --cached --quiet 2>/dev/null; then
    echo ""; echo "  staged:"
    git -C "$path" diff --cached --stat | sed 's/^/    /'
  fi
done < <(git -C "$main_repo" worktree list)
