#!/usr/bin/env bash
# Copy assets/ into a hub dir and render placeholders.
# Usage: hub-scaffold.sh [--force] [--also-link <dir>[,<dir>]] <hub-dir> <repo> <base-branch> [remote]
# --also-link: extra agent dirs (e.g. .agents,.cursor) symlinked to .claude/skills
set -euo pipefail

force=0; also_link=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --force) force=1; shift ;;
    --also-link) also_link="${2:?--also-link needs a value}"; shift 2 ;;
    *) echo "error: unknown option $1" >&2; exit 1 ;;
  esac
done

hub="${1:?hub dir required}"
repo="${2:?repo folder name required}"
base="${3:?base branch required}"
remote="${4:-origin}"

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
assets="$skill_dir/assets"

mkdir -p "$hub"
hub="$(cd "$hub" && pwd)"

render() { # src dest
  local src="$1" dest="$2"
  if [[ -e "$dest" && "$force" -eq 0 ]]; then
    echo "skip: ${dest#"$hub"/} (exists)"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  sed -e "s|{{REPO}}|$repo|g" \
      -e "s|{{BASE_BRANCH}}|$base|g" \
      -e "s|{{REMOTE}}|$remote|g" \
      -e "s|{{HUB}}|$hub|g" \
      "$src" > "$dest"
  [[ "$src" == *.sh ]] && chmod +x "$dest"
  echo "wrote: ${dest#"$hub"/}"
}

while IFS= read -r -d '' src; do
  rel="${src#"$assets"/}"
  rel="${rel%.tmpl}"
  [[ "$rel" == skills/* ]] && rel=".claude/$rel"
  render "$src" "$hub/$rel"
done < <(find "$assets" -type f -print0)

mkdir -p "$hub/worktrees" "$hub/.claude"
[[ -e "$hub/worktrees/.gitkeep" ]] || : > "$hub/worktrees/.gitkeep"

# Optional: other tools' skill dirs -> .claude/skills (symlink, so they never drift)
IFS=',' read -r -a _dirs <<< "$also_link"
for d in ${_dirs[@]+"${_dirs[@]}"}; do
  [[ -n "$d" ]] || continue
  mkdir -p "$hub/$d"
  if [[ ! -e "$hub/$d/skills" && ! -L "$hub/$d/skills" ]]; then
    ln -s ../.claude/skills "$hub/$d/skills"
    echo "linked: $d/skills -> ../.claude/skills"
  fi
done

echo "scaffold done: $hub (repo=$repo base=$base remote=$remote)"
