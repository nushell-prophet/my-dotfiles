# Todo folder - project tasks (including completed ones)

Todo files are created by `create-todo` from `todo.nu` (typically bound to a zellij keybinding). The command writes `todo/YYYYMMDD-HHMMSS.md` with a minimal frontmatter and opens it in helix. If the file is closed unmodified, it (and the `todo/` folder, if it was just created) is removed.

## File naming

`YYYYMMDD-HHMMSS.md` — creation timestamp, no title. Do not rename.

## Frontmatter

```yaml
---
status: draft                    # draft | in_progress | completed | rejected
created: 20260510-143000 #yyyyMMdd-hhmmss
updated: 20260510-143000 #yyyyMMdd-hhmmss
related_files:                   # optional, paths the task touches
  - src/feature/module.nu
  - docs/spec.md
---
```

`status` values:
- `draft` — created, not started (default)
- `in_progress` — being worked on
- `completed` — finished
- `rejected` — abandoned / won't do

`lstd` hides `completed` and `rejected`; everything else shows up as active.

Status is managed manually — edit the frontmatter when state changes. Files stay in `todo/` regardless of status; history lives in git.

## Viewing tasks

```nu
# Active tasks via fzf (preview + ctrl-e to open in zellij)
lstd

# All todos with parsed frontmatter
ls todo | where type == file | where name =~ '\.md$' | insert meta {|i|
  open $i.name | split row -r "---\n?" | get 1? | try { from yaml }
} | select name meta
```

```bash
# By status
grep -l "^status: in_progress" todo/*.md
grep "^status:" todo/*.md | cut -d: -f3 | sort | uniq -c
```

## Task history

```bash
git log -- todo/20260510-143000.md
git log -p -- todo/20260510-143000.md | grep -A1 '^[+-]status:'
```
