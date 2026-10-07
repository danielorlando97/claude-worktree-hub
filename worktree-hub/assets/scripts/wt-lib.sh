#!/usr/bin/env bash
# Shared helpers for the wt-*.sh scripts. Source it; do not run it.

hub_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$hub_root/scripts/hub.conf"

: "${MAIN_REPO:?MAIN_REPO not set in scripts/hub.conf}"
BASE_BRANCH="${BASE_BRANCH:-develop}"
REMOTE="${REMOTE:-origin}"
EXTRA_LINK_NAMES="${EXTRA_LINK_NAMES:-}"

main_repo="$hub_root/$MAIN_REPO"
wt_root="$hub_root/worktrees"

require_main_repo() {
  if [[ ! -e "$main_repo/.git" ]]; then
    echo "error: main repo not found at $main_repo" >&2
    exit 1
  fi
}

branch_to_folder() { printf '%s' "$1" | tr '/' '-'; }

# Resolve a path, branch name or folder name to an absolute worktree path.
resolve_worktree() {
  local name="$1" target
  target="$wt_root/$(branch_to_folder "$name")"
  if [[ -d "$name" && -e "$name/.git" ]]; then
    (cd "$name" && pwd)
  elif [[ -d "$target" ]]; then
    (cd "$target" && pwd)
  elif [[ "$name" == "$MAIN_REPO" && -d "$main_repo" ]]; then
    printf '%s\n' "$main_repo"
  else
    return 1
  fi
}

# --- hard-linked local config ---------------------------------------------------

_real_file() { python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
_inode() { stat -f '%i' "$1" 2>/dev/null || stat -c '%i' "$1"; }
_same_file() {
  local a b
  a="$(_real_file "$1")"; b="$(_real_file "$2")"
  [[ "$a" == "$b" ]] || [[ "$(_inode "$a")" == "$(_inode "$b")" ]]
}

_collect_rel_paths() { # root -> NUL-separated relative paths of shareable files
  local root="$1" path name
  local -a extra=()
  for name in $EXTRA_LINK_NAMES; do
    extra+=(-o -type f -name "$name" -o -type l -name "$name")
  done
  while IFS= read -r -d '' path; do
    printf '%s\0' "${path#"$root"/}"
  done < <(
    find "$root" \
      \( -path "$root/.git" -o -path '*/node_modules' -o -path '*/.venv' \) -prune \
      -o \( -type f \( -name '.env' -o -name '*.env' \) ! -name '*.env.example' \
        ${extra[@]+"${extra[@]}"} \) -print0
  )
}

link_worktree_envs() { # main_repo wt [force]
  local main="$1" wt="$2" force="${3:-0}" rel src dest real
  local linked=0 skipped=0 upgraded=0
  [[ -d "$wt" ]] || { echo "error: worktree not found at $wt" >&2; return 1; }
  main="$(cd "$main" && pwd)"; wt="$(cd "$wt" && pwd)"

  # Main checkout owns the canonical files; turn stray symlinks into hard links.
  while IFS= read -r -d '' rel; do
    if [[ -L "$main/$rel" ]]; then
      real="$(_real_file "$main/$rel")"
      rm -f "$main/$rel"; ln "$real" "$main/$rel"
      echo "upgraded symlink to hard link: $rel"
    fi
  done < <(_collect_rel_paths "$main")

  [[ "$wt" == "$main" ]] && { echo "skip: main checkout owns local config"; return 0; }

  while IFS= read -r -d '' rel; do
    src="$main/$rel"; dest="$wt/$rel"
    [[ -e "$src" ]] || continue
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ ! -L "$dest" ]] && _same_file "$dest" "$src"; then continue; fi
      if [[ "$force" -eq 1 || -L "$dest" ]]; then
        [[ -L "$dest" ]] && upgraded=$((upgraded + 1))
        rm -f "$dest"
      else
        echo "skip (different file; use --force): $rel" >&2
        skipped=$((skipped + 1)); continue
      fi
    fi
    mkdir -p "$(dirname "$dest")"
    if ! ln "$src" "$dest" 2>/dev/null; then
      echo "error: hard link failed for $rel (different volume?)" >&2
      skipped=$((skipped + 1)); continue
    fi
    echo "hard-linked: $rel"
    linked=$((linked + 1))
  done < <(_collect_rel_paths "$main")

  echo "env link done: $linked linked, $upgraded symlink->file, $skipped skipped ($wt)"
}
