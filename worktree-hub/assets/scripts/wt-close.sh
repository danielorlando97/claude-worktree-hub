#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  wt-close.sh <worktree-path|branch|folder> [options]

Options:
  --force          Remove the worktree even with uncommitted changes
  --delete-branch  Delete the local branch after removing the worktree
  --keep-branch    Keep the local branch (default)
  --skip-pr        Close without an open PR (only when the user confirms)

Requires an open PR when the branch has commits vs BASE_BRANCH (see wt-pr-status.sh).
If the PR state cannot be verified (no gh), it also stops: use --skip-pr after checking by hand.
EOF
}

force=0; delete_branch=0; skip_pr=0; wt_arg=""
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --delete-branch) delete_branch=1 ;;
    --keep-branch) delete_branch=0 ;;
    --skip-pr) skip_pr=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "error: unknown option: $arg" >&2; exit 1 ;;
    *) [[ -z "$wt_arg" ]] && wt_arg="$arg" || { echo "error: unexpected argument: $arg" >&2; exit 1; } ;;
  esac
done
[[ -n "$wt_arg" ]] || { usage >&2; exit 1; }
require_main_repo

wt_path="$(resolve_worktree "$wt_arg")" || { echo "error: worktree not found: $wt_arg" >&2; exit 1; }
if [[ "$wt_path" == "$(git -C "$main_repo" rev-parse --show-toplevel)" ]]; then
  echo "error: refusing to close the main worktree" >&2; exit 1
fi

branch="$(git -C "$wt_path" branch --show-current 2>/dev/null || true)"

if ! git -C "$wt_path" diff --quiet 2>/dev/null || ! git -C "$wt_path" diff --cached --quiet 2>/dev/null; then
  if [[ "$force" -eq 0 ]]; then
    echo "error: uncommitted changes in worktree (use --force to discard):" >&2
    git -C "$wt_path" status -sb >&2
    exit 1
  fi
  echo "warning: closing with uncommitted changes (--force)"
fi

if [[ "$skip_pr" -eq 0 ]]; then
  pr_status=0
  "$hub_root/scripts/wt-pr-status.sh" "$wt_arg" || pr_status=$?
  if [[ "$pr_status" -eq 2 ]]; then
    echo "error: no open PR for '$branch' but the branch has work vs $BASE_BRANCH." >&2
    echo "Create the PR first, or pass --skip-pr if closing without one is intentional." >&2
    exit 2
  elif [[ "$pr_status" -eq 3 ]]; then
    echo "error: cannot verify PR state for '$branch' (gh missing, not authenticated, or no remote)." >&2
    echo "Check manually, then pass --skip-pr to close." >&2
    exit 3
  elif [[ "$pr_status" -ne 0 ]]; then
    exit "$pr_status"
  fi
  echo "PR check: ok"
fi

echo "Removing worktree: $wt_path"
git -C "$main_repo" worktree remove "$wt_path" --force
git -C "$main_repo" worktree prune

if [[ "$delete_branch" -eq 1 ]]; then
  if [[ -z "$branch" ]]; then
    echo "warning: no branch checked out; skip branch delete"
  elif git -C "$main_repo" worktree list --porcelain | grep -q "branch refs/heads/$branch\$"; then
    echo "warning: branch $branch still checked out elsewhere; skip delete"
  else
    git -C "$main_repo" branch -D "$branch"
    echo "deleted local branch: $branch"
  fi
elif [[ -n "$branch" ]]; then
  echo "kept local branch: $branch (no worktree)"
fi

echo "closed: $wt_arg"
