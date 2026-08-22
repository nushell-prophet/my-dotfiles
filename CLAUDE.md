# Git Commit Message Conventions

Use this format: `<prefix>: <description>`

## Prefixes

**App-specific:** `broot:`, `zellij:`, `wezterm:`, `helix:`, `nushell:`, `hammerspoon:`, `lazygit:`, etc.

**Conventional commits:**
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code changes without behavior change
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `change:` - Existing functionality changes

## Examples

```
broot: enable kitty keyboard protocol
zellij: use custom helix command for scrollback editing
docs: add conventional commit conventions to commit-git command
refactor: extract todo creation logic to shared module
fix: add --recursive flag to cp commands in toolkit
```

Keep descriptions concise and action-oriented.
Body text follows the global intent-preservation rule — include the user's reasoning whenever the change had a why, not only for complex changes.

# Pushing configs to the machine

`toolkit.nu push-to-machine` copies every tracked config when it is called with no arguments, so a bare `nu toolkit.nu push-to-machine --docker` overwrites the user's live settings — including files nobody in this session touched.
Never run it that way.

- **Push only what you changed.** The command takes module names: `nu toolkit.nu push-to-machine zellij --docker`, or a single file: `nu toolkit.nu push-to-machine helix/config.toml --docker`.
  Scope it to the exact paths your change touched, the same way `git add path/one path/two` does.
- **Look before you copy.** Run it with `--dry-run` first and read the diff.
  What comes back is the change the user is about to lose.
- **A full push is the user's call.** If every module really needs pushing, propose the command and wait — don't run it on your own judgement.
