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

Every file under the `~/.config` paths in `paths-*.csv` comes from this repo, unless the user asked to skip that rule for a change.
So `~/.config` is a git repo whose HEAD is the last push: each push commits what it wrote there, as `push-to-machine: dotfiles@<change-id>`.
An uncommitted change under a tracked path is never normal; it is a reason to find out where it came from.
Other writers own the rest of `~/.config` (cozy writes `nushell/autoload/`, apps write their state), and the rule does not cover them.

- **Call it as a module command, not as a script.** From Bash: `nu --commands 'use toolkit.nu; toolkit push-to-machine zellij --docker --dry-run'`.
  Why: the toolkit defines `push-to-machine`, not `main push-to-machine`, so `nu toolkit.nu push-to-machine …` fails with "Extra positional argument".
- **Push only what you changed.** The command takes module names: `toolkit push-to-machine zellij --docker`, or a single file: `toolkit push-to-machine helix/config.toml --docker`.
  Scope it to the exact paths your change touched, the same way `git add path/one path/two` does.
  Without names it refuses; `--all` pushes everything, and that is the user's call — propose the command and wait.
- **Commit first.** Push refuses files with uncommitted changes in this repo, because the `~/.config` commit names the dotfiles commit it deploys.
- **When push stops on a machine edit, find out where it came from.** It prints the diff and two ways out: `pull-from-machine <file>` to keep the edit (then review and commit it here), or `git -C ~/.config checkout -- <file>` to drop it.
  There is no flag to overwrite without looking.
