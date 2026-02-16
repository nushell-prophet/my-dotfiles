---
allowed-tools: Bash(git:*), Read, Edit
description: Improve git commit messages using patches to preserve original authorship
argument-hint: [branch-name]
---

## Arguments

- `branch-name` (optional): Base branch to compare against (default: master)

## Context

- Current branch: !`git branch --show-current`
- Working directory: !`test -z "$(git status --porcelain 2>/dev/null)" && echo "Clean" || echo "Dirty"`
- Unpublished commits: !`git log --oneline ${ARGUMENTS:-master}..HEAD 2>/dev/null || echo "None"`

## Task

Improve commit messages for unpublished commits in `${ARGUMENTS:-master}..HEAD` using format-patch to preserve original authorship.

### Pre-checks

Abort if: working directory dirty, on base branch, or branch not rebased on latest base. Fetch remote and update base branch first.

### Workflow

1. `git branch <current>_backup_<timestamp>` — safety net
2. `git format-patch ${BASE}..HEAD -o /tmp/git-patches-$$` — generate patches
3. For each `.patch` file: read the diff, then edit `Subject:` line and body. **Preserve `From:` and `Date:` lines** (authorship).
4. `git reset --hard ${BASE} && git am /tmp/git-patches-$$/*.patch` — apply improved patches
5. `git log --format="%h Author: %an <%ae> | %s" ${BASE}..HEAD` — verify authorship

Recovery: `git am --abort && git reset --hard <backup_branch>`

Use conventional commits: feat | fix | change | remove | refactor | docs | test | chore
Focus on WHY the change was made, not just what changed.
