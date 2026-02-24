---
allowed-tools: Bash(jj status:*), Bash(jj diff:*), Bash(jj restore:*), Bash(jj commit:*), Bash(jj describe:*), Bash(jj log:*), Read, Edit
description: Split unrelated changes within a single file into separate commits (use only when explicitly requested; git is the default workflow)
---

## Context

- Current jj status:
!`jj status`

- File to split (user provides as argument): $ARGUMENTS

## Your task

Split unrelated changes in **one file** into separate logical commits.

### Workflow

1. **Analyze the changes**
   - Run `jj diff --git <file>` to see all changes in the file
   - Identify logical groups (e.g., "refactor" vs "new feature" vs "bugfix")
   - Plan how many commits and what each will contain

2. **Save the target state**
   - Read and remember the current file content (this is your target end state)

3. **For each logical group:**
   - `jj restore --from @- <file>` - reset file to parent version
   - Use Edit tool to apply ONLY changes for this group
   - `jj commit -m '<type>: <description>'` - commit this group
   - Repeat for next group (restore from new parent @-)

4. **Verify final state**
   - Read the file content after all commits
   - Compare with saved target state from step 2
   - They MUST match exactly - if not, something went wrong

### Example

File has: typo fix + new function + reformatting

```
# Step 1: See changes
jj diff --git src/utils.ts

# Step 2: Save current content (using Read tool)

# Step 3a: First commit - typo fix
jj restore --from @- src/utils.ts
# Edit: apply only typo fix
jj commit -m 'fix: correct typo in error message'

# Step 3b: Second commit - new function
jj restore --from @- src/utils.ts
# Edit: apply only new function
jj commit -m 'feat: add validateInput helper'

# Step 3c: Third commit - reformatting
jj restore --from @- src/utils.ts
# Edit: apply reformatting
jj commit -m 'refactor: reformat utils module'

# Step 4: Verify final content matches saved target
```

## Important Notes

- **Always verify**: Final file content must match original before splitting
- **If verification fails**: Use `jj undo` to revert and try again
- **Commit message conventions**: Use conventional commits (`feat:`, `fix:`, `refactor:`, etc.)
- **When in doubt**: Ask user which changes belong together
