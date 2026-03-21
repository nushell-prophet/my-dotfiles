---
name: keep-a-changelog
description: >
  This skill should be used when the user asks to "create a changelog",
  "add a changelog entry", "update the changelog", "release a new version",
  "cut a release", "validate the changelog", "init changelog",
  "add to unreleased", "prepare release notes", "bump version",
  mentions "CHANGELOG.md", "keep a changelog", "what changed",
  or works on release management involving a changelog file.
  Provides the Keep a Changelog 1.1.0 format and operations.
version: 0.1.0
---

# Keep a Changelog

Manage `CHANGELOG.md` files following the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) format.

## Format Overview

The file is named `CHANGELOG.md` at the project root. Structure:

1. **Title**: `# Changelog` with introductory blurb referencing Keep a Changelog and SemVer
2. **Unreleased section**: `## [Unreleased]` — always present at top, collects pending changes
3. **Version sections**: `## [X.Y.Z] - YYYY-MM-DD` — reverse chronological order
4. **Change categories** within each version (include only those with entries, in this order):
   - `### Added` — new features
   - `### Changed` — changes in existing functionality
   - `### Deprecated` — soon-to-be removed features
   - `### Removed` — now removed features
   - `### Fixed` — bug fixes
   - `### Security` — vulnerability fixes
5. **Comparison links** at file bottom — link references for every version heading

For the complete format specification and templates, consult **`references/format-spec.md`**.

## Operations

### Initialize a Changelog

Create `CHANGELOG.md` at the project root. Include:

- `# Changelog` heading
- Introductory paragraph referencing Keep a Changelog and Semantic Versioning
- `## [Unreleased]` section (empty or with initial entries)
- If the project already has releases, add version sections for existing tags
- Comparison link references at the bottom

Detect the repository's remote URL and tagging convention (e.g., `v1.0.0` vs `1.0.0`) from git to generate correct comparison links. If no git remote exists, use placeholder URLs and note them.

### Add an Entry

Add entries under `## [Unreleased]` in the appropriate category subsection.

1. Read the existing `CHANGELOG.md`
2. Determine the correct category (Added, Changed, Deprecated, Removed, Fixed, Security)
3. Create the category heading under `[Unreleased]` if it doesn't exist yet — maintain standard category order
4. Append the entry as a markdown list item: `- Description of change (commit_hash)`
5. Every entry MUST include the short git commit hash (7 chars) that introduced the functionality, appended in parentheses. If multiple commits contributed, list all: `(abc1234, def5678)`. Use `git log` to find the right commit.
6. Keep entries concise and human-readable — start with a capital letter, no trailing period

When the user doesn't specify a category, infer it from context:
- New feature/capability → Added
- Modification to existing behavior → Changed
- Bug fix → Fixed
- Security patch → Security
- Feature removal → Removed
- Deprecation notice → Deprecated

If ambiguous, prompt for clarification.

### Release a Version

Move `[Unreleased]` entries into a new version section.

1. Read the current `CHANGELOG.md`
2. Determine the new version number — ask the user if not specified, or suggest based on changes:
   - Breaking changes → major bump
   - New features → minor bump
   - Bug fixes only → patch bump
3. Create a new version heading: `## [X.Y.Z] - YYYY-MM-DD` using today's date
4. Move all entries from `[Unreleased]` into the new version section
5. Leave `## [Unreleased]` empty (with no category subsections)
6. Insert the new version section between `[Unreleased]` and the previous latest version
7. Update comparison links at the bottom:
   - Update `[Unreleased]` link to compare new version tag to HEAD
   - Add new version link comparing to previous version
8. Use the project's existing tag format (detect from git tags or existing links)

### Validate a Changelog

Check `CHANGELOG.md` for format compliance. Report issues:

- Missing or incorrect `# Changelog` heading
- Missing `## [Unreleased]` section
- Invalid version header format (must be `## [X.Y.Z] - YYYY-MM-DD`)
- Invalid date format (must be ISO 8601)
- Unrecognized change categories (only the six standard ones allowed)
- Wrong category order within a version
- Versions not in reverse chronological order
- Missing or incorrect comparison links at bottom
- Empty change categories (should be omitted if empty)
- Entries not starting with `- `

Report findings as a checklist with pass/fail indicators. Offer to fix any issues found.

## Writing Style — Don't Dump Git Logs

A changelog is for **humans**, not machines. Every entry must be written from the user's perspective, describing what changed for them — not what happened in the code.

### Rewrite, don't copy

When deriving entries from git history, **never** paste commit messages verbatim. Rewrite them:

- **BAD**: `fix: correct Rule 5 (Big X smushing) string literals in smush-char` (commit message)
- **GOOD**: `Incorrect horizontal smushing with Big X (Rule 5)` (user-visible bug)

- **BAD**: `feat: use par-each for faster font showcase rendering` (implementation detail)
- **GOOD**: _(omit — internal optimization, not user-facing)_

- **BAD**: `Rename setup → setup-fonts, make compile private` (code-level refactor)
- **GOOD**: `Rename \`setup\` to \`setup-fonts\`` (only the part the user sees)

### What belongs

- Features and behaviors the user interacts with
- Bugs the user could have encountered
- Breaking changes to commands, flags, APIs, or config
- Performance improvements the user would notice

### What doesn't belong

- Internal refactors, variable renames, code reorganization
- Implementation details (function names, data structures, algorithms)
- Build/CI changes invisible to the user
- Multiple entries for what is really one user-facing change — merge them

### Merge related entries

If several commits contribute to one feature, write **one** entry:

- **BAD**: Three entries for "add gradient support", "add gradient presets", "add gradient tab completion"
- **GOOD**: One entry: `ANSI color and gradient support with named presets`

### Initial releases have no Fixed/Changed

The first release (`0.0.1`, `1.0.0`, etc.) is all new — nothing was "fixed" or "changed" from the user's perspective. Use only `### Added`.

## Key Rules

- **Never** invent change categories beyond the six defined ones
- **Always** keep versions in reverse chronological order (latest first)
- **Always** maintain the `[Unreleased]` section, even if empty
- **Always** use ISO 8601 dates (`YYYY-MM-DD`)
- **Always** include the short commit hash in parentheses at the end of every entry
- **Omit** empty categories — only include categories that have entries
- **Preserve** existing comparison links and update them correctly on release
- Yanked releases use: `## [X.Y.Z] - YYYY-MM-DD [YANKED]`

## Additional Resources

### Reference Files

For the complete format specification, file template, comparison link rules, and entry formatting guidelines, consult:
- **`references/format-spec.md`** — Full Keep a Changelog 1.1.0 specification with templates
