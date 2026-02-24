---
allowed-tools: Bash(jj status:*), Bash(jj commit:*), Bash(jj diff:*), Bash(jj describe:*), Bash(jj squash:*), Bash(jj new:*), Bash(jj log:*), Bash(jj file list:*), Bash(jj file track:*), Bash(jj file untrack:*), Bash(jj metaedit:*)
description: Create a jj commit (use only when explicitly requested; git is the default workflow)
---

## Context

- Current jj status:
!`jj status`

- Change summary:
!`jj diff --stat`

- Recent commits:
!`jj log --limit 5`

## Task

Commit only files created, edited, or deleted in this session. Skip pre-existing changes in `jj status`.

Group unrelated changes into separate commits. For unrelated changes within a single file, ask user to run `/jj-split-file-for-commit <file>`.

Commit pattern — always use:
```bash
jj commit <files> -m 'message' && jj metaedit @- --update-author
```

Never use interactive commands (`jj split`, `jj squash -i`). Always specify `-m` flag.

Use conventional commits format: feat | fix | change | remove | refactor | docs | test | chore
Breaking changes: add '!' after type (e.g., `feat!: change API format`)
