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

Keep descriptions concise and action-oriented. Body text follows the global intent-preservation rule — include the user's reasoning whenever the change had a why, not only for complex changes.
