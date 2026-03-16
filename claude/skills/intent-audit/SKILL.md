---
name: intent-audit
description: >
  Audit whether user intent has been preserved in code artifacts.
  Use this skill when the user asks to check, audit, or verify that their
  reasoning and decisions were captured in commits, comments, or documentation.
  Also trigger when the user says "check intent", "did you capture why",
  "audit the session", "review what was lost", "verify commits match discussion",
  or references preserving decision context. Trigger at the end of a coding
  session if the user asks for a final review before finishing.
---

# Intent Audit

Verify that the user's stated reasoning, decisions, constraints,
and rejected alternatives have been captured in the session's artifacts:
commit messages, inline comments, and documentation.

## Core Principle

The user's words are the primary source of truth.
Code shows WHAT. The user explained WHY.
If the WHY is not recorded next to the WHAT, knowledge is lost.

## Audit Process

### Step 1: Gather User Inputs

Scan the current conversation for user messages that contain:

- **Decisions**: "let's do X", "use Y instead of Z"
- **Reasoning**: "because", "since", "the reason is", "this way we"
- **Constraints**: "must", "can't", "don't", "never", "always"
- **Rejected alternatives**: "not X because", "I tried Y but",
  "don't use Z", "the problem with W is"
- **Preferences**: "I prefer", "I want", "it should"
- **Domain knowledge**: facts, references, explanations of how
  things work that informed the implementation

Extract each as a discrete intent item. Quote the user closely —
do not paraphrase into something more "polished".

### Step 2: Gather Artifacts

Collect all artifacts produced in this session:

```
git log --since="<session_start>" --format="%H %s%n%b" --no-merges
git diff <before_session>..HEAD
```

Also scan changed files for inline comments added or modified
during this session.

If the session produced documentation files (ADR, CHANGELOG,
README updates), include those too.

### Step 3: Cross-Reference

For each intent item from Step 1, check whether it appears in:

1. A commit message body (not just the subject line)
2. An inline code comment at the relevant decision point
3. A documentation file

Mark each intent item as:

- **Captured** — reasoning is recorded, traceable to the user's words
- **Partial** — the decision is visible but the reasoning is missing
  (e.g., code does X but nowhere says why not Y)
- **Lost** — no trace in any artifact

### Step 4: Report

Present findings as a list grouped by status.
For each lost or partial item:

- Quote the user's original statement
- Identify where it should be captured
  (which commit, which file, which line)
- Propose the specific text to add

Format:

```
## Intent Audit Report

### Lost (N items)

1. User said: "don't use regex here, nested brackets break it"
   → File: src/parser.nu, line 47
   → Proposed comment: # Why not regex: nested brackets
     cause catastrophic backtracking. User tested this.
   → Proposed commit amend: add reasoning to commit abc123

### Partial (N items)
...

### Captured (N items)
...
```

### Step 5: Fix

After presenting the report, ask the user which items to fix.
Then apply fixes:

- For missing commit message context: `git commit --amend`
  or `git notes add` if amending would disrupt history
- For missing inline comments: add them directly
- For missing documentation: create or update the relevant file

Do not auto-fix without user confirmation.

## What Counts as "Captured"

A decision is captured if a future reader (human or LLM)
who has never seen this conversation can understand:

1. What was decided
2. Why it was decided this way
3. What alternatives were considered and rejected

All three must be present. If only (1) is there, mark as Partial.

## What Does NOT Count

- Git diff showing the code change — this is WHAT, not WHY
- A commit subject line like "implement parser" — too vague
- A comment that restates the code: `# split the string` above
  a split operation — this is noise, not intent

## Edge Cases

- If the user gave reasoning verbally but it's obvious from
  the code (e.g., using a well-known pattern), mark as Partial
  with a note — "obvious to experts, but explicit comment
  would help future LLM sessions"
- If the session had no commits (exploration/discussion only),
  report that no artifacts exist to audit and suggest
  creating a summary document
- If the user's reasoning contradicts what was implemented,
  flag this as a discrepancy, not a missing intent

## Scope Control

Audit only the current session's conversation and artifacts.
Do not crawl entire repo history.
Do not audit code that wasn't discussed or changed in this session.
