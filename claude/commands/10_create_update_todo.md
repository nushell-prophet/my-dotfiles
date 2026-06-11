---
allowed-tools: Bash(date:*), Bash(ls:*), Bash(git add:*), Bash(git commit:*), Bash(git mv:*), Write, Glob, Read
description: Create new or update existing todo file
argument-hint: <task description> or @path/to/todo.md
---

# Create or update todo file

Working with todo files - creating new or updating existing:

- **New todo**: Create with name in format `YYYYMMDD-HHMM-short_title.md`
- **Existing todo**: Update content, preserve filename
- **Location**: All todo files always remain in `todo/` folder

## Input data

**Input data:** $ARGUMENTS

**Mode determination:**

- If starts with `@` - this is a path to existing todo for update
- Otherwise - this is a description for creating new todo
- If empty - stop execution

## Context

- Current date and time: !`date +%Y%m%d-%H%M`
- Session UID: ${CLAUDE_SESSION_ID}
- Todo rules: @todo/CLAUDE.md

## Task

1. **Mode determination and analysis**:

   - If file path (@path/to/todo.md) - read and analyze existing todo
   - If task description - analyze for creating new todo

   Determine:

   - What specifically needs to be done
   - Which files are affected (existing or new)
   - What requirements are implied
   - Possible risks and dependencies

2. **File location**:

   - **For update**: use existing location
   - **For creation**: always in `todo/` folder
   - **IMPORTANT**: Todo files are NOT moved elsewhere. Link to code is managed through frontmatter field `related_files`

3. **Create/update todo file**:

   **For new file** use structure:

   ```markdown
   ---
   task-name: [brief name based on analysis]
   status: draft
   created: [current date YYYY-MM-DD]
   updated: [current date YYYY-MM-DD]
   original_session: [session UID from Context]
   ---

   # [Task title]

   ## Task from user (original)

   [Original user task text - PROTECTED from modification]

   ## Task description (extended version)

   [Detailed description: what needs to be done, context, goal, expected result]

   ## Requirements

   - [ ] Functional requirements
   - [ ] Technical constraints
   - [ ] Success criteria

   ## Implementation plan

   - [ ] Step 1: [description]
   - [ ] Step 2: [description]
   - [ ] ...

   ## Affected files

   - Existing files: [if known]
   - New files: [if known]
   ```

   **For existing file** (compactness principle):
   - Update status and updated in frontmatter (original_session stays unchanged — it points to the creating session)
   - Modify/replace any sections for brevity (except "Task from user (original)")
   - Remove duplicate information
   - Block "Task from user (original)" - PROTECTED, do not modify
   - Preserve change history (if exists)

4. **Git operations**:

   Add file to git and create commit with **MANDATORY** reference to todo file:

   Format for new: `todo add: [brief description] (todo/YYYYMMDD-HHMM-title.md)`
   Format for update: `todo update: [what changed] (todo/YYYYMMDD-HHMM-title.md)`

   Examples:
   - `todo add: data analysis (todo/20250911-1430-analytics-task.md)`
   - `todo update: added requirements (todo/20250911-1430-analytics-task.md)`

## Critical rules

- **FIRST ACTION on update**: Check filename and add short_title if missing (via `git mv` + separate commit)
- On creation: filename format `YYYYMMDD-HHMM-short_title.md` (MANDATORY with short_title)
- Mandatory todo reference in commit with full path
- All todo files always remain in `todo/` (NOT moved elsewhere)
- Block "Task from user (original)" - PROTECTED from changes by command
- Use user's task language for entire file
