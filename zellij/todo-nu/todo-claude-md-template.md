# todo/ — tasks the user wrote for you

Files here are created by `create-todo` in `todo.nu` (bound to a zellij key). The name is the date, `todo/YYYYMMDD.md`, with `-1`, `-2`, … when a second task lands the same day. Do not rename.

## Keep the task text verbatim

The text in the file is the user's own. Do not reword, reformat, or tidy it up unless the user explicitly asks. Your work goes below it, never over it.

## Log the result in the same file

Append what you did to the bottom of the file: the result, what changed, what is left.

- The file is already tracked in git — commit it together with the change it describes.
- The file is not tracked yet — write the result back, then ask the user whether to commit it.

## Delete the file when the task is fully done

Once the report is committed, remove the file. Git history keeps it, and a finished task left lying here only misleads the next session. A task that is partly done stays, with `status: in_progress`.

## Frontmatter

```yaml
---
status: draft #draft | in_progress | completed | rejected
created: '20260510' #yyyyMMdd
updated: '20260510' #yyyyMMdd
---
```

`lstd` lists everything except `completed` and `rejected`. Status is edited by hand.
