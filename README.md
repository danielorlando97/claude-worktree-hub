# /worktree-hub — parallel git checkouts, scaffolded

[![skills.sh](https://skills.sh/b/danielorlando97/claude-worktree-hub)](https://skills.sh/danielorlando97/claude-worktree-hub)
[![License: MIT](https://img.shields.io/badge/license-MIT-black)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-black)](https://claude.ai/code)

**Turns any git repo into a worktree hub: the main checkout, a `worktrees/` folder, helper scripts and agent rules, so you and your agents can work on several branches at once.**
No more stashing, no more agents editing the wrong checkout.

---

## The problem

You start a second task while the first is half done, so you stash, switch branches, and lose your `.env` or your place. Or you give an agent its own `git worktree add` at a random path, and a week later nobody knows which folder owns which branch, which ones have an unpublished commit, or why the new checkout has no `.env`.

---

## Install

```bash
npx skills@latest add danielorlando97/claude-worktree-hub
```

Or as a Claude Code plugin:

```
/plugin marketplace add danielorlando97/claude-worktree-hub
```

---

## Workflow

```
 remote URL ──► /worktree-hub init    ─┐
                                       ├─► hub/  ──► /worktree-hub check
 existing clone ► /worktree-hub convert┘     │
                                             ├─ wt-add.sh -b feat/x origin/<base>  → worktrees/feat-x
                                             ├─ wt-status.sh                       → every checkout, one view
                                             └─ wt-close.sh feat-x                 → PR gate, then remove
```

---

## What gets saved

```
hub/
├── AGENTS.md  CLAUDE.md     rules for agents: use the scripts, protect the main checkout
├── <repo>/                  main checkout; owns .env files and git metadata
├── worktrees/               one folder per branch (feat/a/b → feat-a-b)
├── scripts/
│   ├── hub.conf             repo, base branch, remote, extra shared files
│   └── wt-*.sh              add, close, remove, status, pr-status, link-env
└── .claude/skills/          create-worktree, close-worktree
```

`.env` and `*.env` files are hard-linked from the main checkout into every worktree, so there is one copy to edit.

---

## Commands

| Command | What it does |
|---|---|
| `init <remote-url> [hub-dir]` | Clone into a new hub and scaffold everything |
| `convert [repo-path]` | Move an existing clone (and its worktrees) into a hub, with a confirmation gate and rollback steps |
| `check [hub-dir]` | Audit a hub against the layout; report drift, fix only on request |
| `extend [hub-dir]` | Extra shared files, other tools' skill dirs (`--also-link`), PR conventions |

The close script refuses to remove a worktree that has unpublished work and no open PR. If `gh` is missing it says it cannot verify, instead of guessing.

---

## Philosophy

A worktree is only cheap if nobody has to remember where it is. So the folder name is a pure function of the branch, creation goes through one script, and closing goes through another that checks you are not about to lose work. Rules that live in scripts get followed; rules that live in someone's head do not.

---

## Requirements

- git (a recent version; `git worktree repair` is used by `convert`)
- bash and python3 (macOS/Linux)
- `gh`, optional: needed for the PR gate

---

## License

MIT © [danielorlando97](https://github.com/danielorlando97)
