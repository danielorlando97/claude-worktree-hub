# worktree-hub

A skill that scaffolds and audits a workspace where one git repository is worked on through several parallel checkouts, for people and coding agents.

## Language

**Hub**:
The workspace root directory that contains the main checkout, the worktrees folder, the scripts and the agent instructions. It is not itself a git repository.
_Avoid_: Suite, monorepo root, workspace (ambiguous with IDE workspace)

**Main checkout**:
The one full clone of the repository inside the hub, which owns the local configuration files and the git metadata.
_Avoid_: Origin clone, primary repo, root repo

**Worktree**:
An additional checkout of one branch of the repository, living under the hub's `worktrees/` folder.
_Avoid_: Branch folder, copy, clone

**Worktree folder**:
The directory name of a worktree, derived from its branch by replacing every `/` with `-`. It cannot be mapped back to the branch.
_Avoid_: Worktree id (use only as a CLI argument name)

**Base branch**:
The branch new worktrees fork from and pull requests target, taken from the repository's default branch unless stated otherwise.
_Avoid_: Trunk, mainline, develop (a value, not the concept)

**Shared local config**:
Untracked files such as `.env` that exist once in the main checkout and appear in every worktree as hard links.
_Avoid_: Env sync, copied env

**PR gate**:
The rule that a worktree holding unpublished work is not closed until an open pull request exists or the user explicitly waives it.
_Avoid_: PR check, close guard

**Scaffold**:
The set of files the skill writes into a hub from its templates, never overwriting existing ones without `--force`.
_Avoid_: Bootstrap, template output
