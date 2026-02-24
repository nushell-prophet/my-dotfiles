---
allowed-tools: Task, Bash(git:*)
description: Create a git commit with smart staging for session work
---

Commit current session changes using the commit-git subagent.
Pass only files created, edited, or deleted in this session.
Include a brief motivation — why the changes were made, not just what changed.
If HEAD is detached, jj was used in parallel — create a new branch from the current commit and work with it.
