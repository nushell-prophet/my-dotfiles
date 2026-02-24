---
allowed-tools: Bash(jj:*), Read, Edit
description: Improve jj commit messages while preserving original authorship (use only when explicitly requested; git is the default workflow)
argument-hint: [base-revision]
---

## Arguments

- `base-revision` (optional): Base revision to compare against (default: main)

## Context

- Current revision: !`jj log -r @ --no-graph --template 'change_id.short() ++ " " ++ description.first_line()' 2>/dev/null`
- Working copy clean: !`jj diff --stat 2>/dev/null | grep -q . && echo "Has changes" || echo "Clean"`

## Task

Review and improve commit messages in range `${ARGUMENTS:-main}..@-`.

List commits with their current messages:
```bash
jj log -r "${ARGUMENTS:-main}..@-" --template '
change_id.short() ++ " by " ++ author.name() ++ "\n" ++
"  " ++ description.first_line() ++ "\n"
'
```

For each commit needing improvement, read its diff to understand the change, then:
```bash
jj describe <change_id> -m "type: improved message"
```

`jj describe` preserves original authorship automatically.

Use conventional commits format: feat | fix | change | remove | refactor | docs | test | chore
Focus on capturing WHY the change was made, not just what changed.
