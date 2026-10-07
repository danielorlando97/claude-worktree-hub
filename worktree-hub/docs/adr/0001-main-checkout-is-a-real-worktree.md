---
status: accepted
---

# Main checkout is a real worktree inside the hub

The hub holds a normal clone (`<repo>/`) next to `worktrees/`, instead of a bare repository with every branch as a sibling worktree. We chose this because the main checkout doubles as the owner of shared local config and stays usable by IDEs and tools that expect a regular repo, and because `convert` can move an existing clone in without re-cloning.

## Considered Options

- **Bare repo + sibling worktrees** (`git clone --bare`): the common community pattern, uniform and no privileged checkout. Rejected: nothing owns `.env` files, existing clones can't be converted in place, and many tools misbehave on bare repos.

## Consequences

The main checkout must never be removed or repointed by the scripts; `wt-close.sh` and `wt-remove.sh` refuse it.
