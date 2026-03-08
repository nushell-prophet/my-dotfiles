# Keep a Changelog 1.1.0 — Format Specification

Source: <https://keepachangelog.com/en/1.1.0/>

## Complete File Template

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New feature description

## [1.1.0] - 2024-03-15

### Added

- New feature A
- New feature B

### Fixed

- Bug fix description

## [1.0.0] - 2024-01-01

### Added

- Initial release

[Unreleased]: https://github.com/user/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

## Change Categories

Exactly six categories are defined. Use only those that have entries — omit empty categories:

| Category       | Purpose                                  |
|----------------|------------------------------------------|
| `### Added`    | New features                             |
| `### Changed`  | Changes in existing functionality        |
| `### Deprecated` | Soon-to-be removed features            |
| `### Removed`  | Now removed features                     |
| `### Fixed`    | Bug fixes                                |
| `### Security` | Vulnerability fixes                      |

**Ordering within a version**: Categories appear in the order listed above (Added first, Security last). Only include categories that have entries.

## Version Header Format

```
## [VERSION] - YYYY-MM-DD
```

- Version number follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html): `MAJOR.MINOR.PATCH`
- Date is ISO 8601 format: `YYYY-MM-DD`
- Version text is a markdown link reference (resolved at bottom of file)
- Latest version appears first (reverse chronological)

### Yanked Releases

Pulled/retracted releases append `[YANKED]`:

```
## [1.0.1] - 2024-02-01 [YANKED]
```

## Unreleased Section

- Always present at the top (below the file header)
- Collects changes not yet in a release
- Header: `## [Unreleased]`
- When cutting a release, move Unreleased entries into a new version heading and add a fresh empty `## [Unreleased]` section

## Comparison Links

At the bottom of the file, define link references for every version heading:

```markdown
[Unreleased]: https://github.com/user/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

Rules:
- `[Unreleased]` compares the latest release tag to `HEAD`
- Each version compares its tag to the previous version's tag
- The very first version links to its release tag (no comparison)
- Tag format (`v1.0.0` vs `1.0.0`) should match the project's tagging convention

## Entry Format

Each entry is a markdown list item:

```markdown
- Brief, human-readable description of the change
```

Guidelines:
- Start with a capital letter
- No trailing period
- One logical change per entry
- Reference issue/PR numbers where helpful: `- Fix crash on startup ([#42](https://github.com/user/repo/issues/42))`

## Guiding Principles

1. Changelogs are for humans, not machines
2. There should be an entry for every single version
3. The same types of changes should be grouped
4. Versions and sections should be linkable
5. The latest version comes first
6. The release date of each version is displayed
7. Mention whether the project follows Semantic Versioning
