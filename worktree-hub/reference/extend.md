# extend — project-specific adjustments

The scaffold is generic. Adjust it through `scripts/hub.conf` and the hub `AGENTS.md`; do not fork the scripts.

## 1. Extra shared files (hard-linked into every worktree)

Default: `.env`, `*.env` (not `*.env.example`). Add exact basenames:

```bash
EXTRA_LINK_NAMES="local.settings.json secrets.local.yaml"
```

Then `./scripts/wt-link-env.sh --all`. Limits to tell the user: same filesystem only; an editor that saves by replacing the file un-links that worktree's copy (`--force` relinks).

## 2. Other tools' skill directories

The hub's skills live in `.claude/skills/`. For other tools, symlink instead of copying:

```bash
<skill-dir>/bin/hub-scaffold.sh --also-link .agents,.cursor <HUB> <REPO> <BASE_BRANCH> [REMOTE]
```

Existing files are skipped, so this is safe to re-run.

## 3. PR conventions

`close-worktree` falls back to `gh pr create --base $BASE_BRANCH`. If the repo documents its own PR process, add one line to the hub `AGENTS.md` pointing at it; the skill already tells the agent to follow documented conventions first.

## 4. Relocatable hub (opt-in)

`git worktree repair` already fixes moved worktrees. Users who move the hub often and run git ≥ 2.48 everywhere can set `git config worktree.useRelativePaths true` in the main checkout (verify `git help worktree` mentions `--relative-paths` first). Not enabled by default: older git and some IDE integrations don't understand it.

## 5. Running the same service in several worktrees

Not scaffolded: it depends on the project's Makefile/compose setup. If asked, design it for the stack: each worktree needs its own host port, container name and data volume, and the main checkout keeps the default ports.

After any change, run `check`.
