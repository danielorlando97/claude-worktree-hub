#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/wt-lib.sh"

base_branch="${WT_PR_BASE:-$BASE_BRANCH}"
wt_arg="${1:-}"

[[ -n "$wt_arg" ]] || {
  cat >&2 <<'EOF'
Usage: wt-pr-status.sh <worktree-path|branch|folder>

Prints branch, commits vs base, push state and open PR URL (if any).
Base branch: BASE_BRANCH from hub.conf (override with WT_PR_BASE).
Exit 0: PR open, or nothing to publish. Exit 2: work exists but no PR.
Exit 3: cannot verify (gh missing/unauthenticated) and there is work to publish.
EOF
  exit 1
}
require_main_repo

wt_path="$(resolve_worktree "$wt_arg")" || { echo "error: worktree not found: $wt_arg" >&2; exit 1; }
branch="$(git -C "$wt_path" branch --show-current 2>/dev/null || true)"
[[ -n "$branch" ]] || { echo "error: detached HEAD in worktree" >&2; exit 1; }

git -C "$wt_path" fetch "$REMOTE" --quiet 2>/dev/null || true

base_ref="$REMOTE/$base_branch"
if ! git -C "$wt_path" show-ref --verify --quiet "refs/remotes/$base_ref"; then
  echo "warning: $base_ref not found after fetch" >&2
  base_ref="$base_branch"
fi

ahead="$(git -C "$wt_path" rev-list --count "$base_ref..HEAD" 2>/dev/null || echo 0)"
behind="$(git -C "$wt_path" rev-list --count "HEAD..$base_ref" 2>/dev/null || echo 0)"

push_state="no-upstream"
if git -C "$wt_path" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  unpushed="$(git -C "$wt_path" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)"
  if [[ "$unpushed" -eq 0 ]]; then push_state="pushed"; else push_state="ahead-of-origin-by-$unpushed"; fi
fi

pr_url=""; pr_state=""; can_verify=1
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if pr_json="$(gh pr view "$branch" --json url,state -q '.url + " " + .state' 2>/dev/null)"; then
    pr_url="${pr_json%% *}"; pr_state="${pr_json#* }"
  fi
else
  can_verify=0
fi

echo "worktree: $wt_path"
echo "branch: $branch"
echo "base: $base_ref"
echo "commits_ahead_of_base: $ahead"
echo "commits_behind_base: $behind"
echo "push: $push_state"
echo "pr_url: ${pr_url:-none}"
echo "pr_state: ${pr_state:-none}"

[[ -n "$pr_url" ]] && exit 0
if [[ "$ahead" -gt 0 ]] || [[ "$push_state" == ahead-of-origin-by-* ]]; then
  [[ "$can_verify" -eq 1 ]] && exit 2
  echo "pr_check: unverifiable (gh missing or not authenticated)" >&2
  exit 3
fi
exit 0
