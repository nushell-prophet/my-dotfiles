# Dotfiles synchronization toolkit
#
# Manages syncing configuration files between this Git repository and the local machine.
# Uses two CSV files for configuration:
#   - paths-default.csv: Single column (full-path) with glob patterns. Repo paths are derived:
#     ~/.config/X/... → X/...  |  ~/.X/... → X/...
#   - paths-local.csv: Optional local overrides with status column (update, ignore)
#
# Commands:
#   pull-from-machine        - Copy configs from machine into repo (module names + --docker supported)
#   push-to-machine          - Copy configs from repo to machine; name the modules or pass --all (--dry-run for preview)
#   gen-no-wrap              - Regenerate helix/config-no-wrap.toml from helix/config.toml
#   fill-candidates          - Find new config files to potentially track
#   cleanup-paths-not-in-csv - List repo files not tracked in CSV

const excluded_locals = [**/.git/** **/.jj/** toolkit.nu macos-fresh/* paths-default.csv paths-docker.csv README.md .gitignore CLAUDE.md .DS_Store .claude/settings.local.json paths-local.csv]

# Base-relative: glob --exclude matches them against each scanned parent dir.
const excluded_scan_globs = [.git/**]

# Every file under the tracked ~/.config paths comes from this repo, so the git repo
# there records what was pushed last: HEAD is the baseline a machine edit is told apart by.
const config_root = '~/.config'

export def main [] { }

# Check if a file has uncommitted changes in its git repository
def has-uncommitted-changes [path: path] {
    if not ($path | path exists) { return false }

    let dir = if ($path | path type) == 'dir' { $path } else { $path | path dirname }

    # Check if inside a git repo
    let git_check = do { cd $dir; ^git rev-parse --git-dir } | complete
    if $git_check.exit_code != 0 { return false }

    # Check for uncommitted changes (staged or unstaged)
    let status = do { cd $dir; ^git status --porcelain -- $path } | complete
    ($status.stdout | str trim | is-not-empty)
}

# Check paths for uncommitted changes, print error if found. Returns true if dirty.
def check-dirty-files [paths: table field: string context: string] {
    let dirty = $paths | where { has-uncommitted-changes ($in | get $field) }
    if ($dirty | is-not-empty) {
        print $"(ansi red)Error: The following ($context) have uncommitted changes:(ansi reset)"
        $dirty | get $field | each { print $"  ($in)" }
        print $"\nCommit or stash changes first, or use --force to overwrite."
        true
    } else {
        false
    }
}

# The ones of `paths` that differ from HEAD in the git work tree at `root`:
# modified, deleted or untracked. Deleted paths count too, unlike has-uncommitted-changes.
def dirty-paths [root: path paths: list<path>]: nothing -> list<path> {
    if ($paths | is-empty) { return [] }
    ^git -C $root status --porcelain=v1 -z --untracked-files=all -- ...$paths
    | split row (char nul)
    | where $it != ''
    | each {|line| $root | path join ($line | str substring 3..) }
}

# On the first push to a machine, make ~/.config a git repo and commit the tracked
# files already there, so whatever the push overwrites stays in its history.
# Why an explicit pathspec: ~/.config also holds files nobody tracks, secrets among them.
def ensure-config-repo [root: path paths: list<path>] {
    if ($root | path join '.git' | path exists) { return }
    mkdir $root
    ^git init --quiet $root
    let existing = $paths | where { path exists }
    if ($existing | is-empty) { return }
    ^git -C $root add -- ...$existing
    ^git -C $root commit --quiet --message 'push-to-machine: baseline before the first push' -- ...$existing
}

# Why: cozy bootstrap pushes from ~/repos/dotfiles, a vendored copy with no .git.
def source-is-repo []: nothing -> bool {
    let top = ^git rev-parse --show-toplevel | complete
    $top.exit_code == 0 and ($top.stdout | str trim) == (pwd | path expand)
}

# The dotfiles commit a push deploys: its Change-Id prefix, or the short sha without one.
def source-id []: nothing -> string {
    if not (source-is-repo) { return 'vendored-copy' }
    let id = ^git log -1 '--format=%(trailers:key=Change-Id,valueonly)' | str trim
    if $id != '' { $id | str substring 0..7 } else { ^git rev-parse --short HEAD | str trim }
}

# Derive repo path from full machine path using convention:
#   ~/.config/X/... → X/...
#   ~/.X/...        → X/...
def derive-repo-path [fullpath: string] {
    let expanded = $fullpath | path expand --no-symlink
    let home = $nu.home-dir
    let config_prefix = $home | path join '.config'

    if ($expanded | str starts-with $config_prefix) {
        $expanded | str replace $"($config_prefix)/" ''
    } else if ($expanded | str starts-with $"($home)/.") {
        $expanded | str replace $"($home)/." ''
    } else {
        $expanded | str replace $"($home)/" ''
    }
}

# Extract static prefix from glob pattern (everything before first glob char)
def glob-base [pattern: string] {
    $pattern | str replace -r '[\*\?\[\{].*$' ''
}

# Read paths-default.csv, expand globs, and derive repo paths
def open-configs [paths_file: string = 'paths-default.csv'] {
    open $paths_file
    | get full-path
    | each {|pattern|
        let expanded = $pattern | path expand --no-symlink
        if ($pattern !~ '[\*\?\[\{]') {
            return [{full-path: $expanded path-in-repo: (derive-repo-path $expanded)}]
        }

        let repo_pattern = derive-repo-path $expanded
        let machine_base = glob-base $expanded
        let repo_base = glob-base $repo_pattern

        # Glob from machine (for pull) and repo (for push when machine dir missing)
        let from_machine = glob $expanded --no-dir
            | each {|f| {full-path: $f path-in-repo: (derive-repo-path $f)} }

        let from_repo = glob $repo_pattern --no-dir
            | each {|f|
                let repo_path = $f | path relative-to (pwd)
                let rel = $repo_path | path relative-to $repo_base
                {path-in-repo: $repo_path full-path: ($machine_base | path join $rel)}
            }

        $from_machine | append $from_repo | uniq-by path-in-repo
    }
    | flatten
}

# Read paths-local.csv if it exists, otherwise return empty list
def open-local-configs [] {
    if ('paths-local.csv' | path exists) {
        open paths-local.csv | update full-path { path expand --no-symlink }
    } else { [] }
}

# {full-path, path-in-repo, in-repo, on-machine, status?}
def expand-paths [paths_file: string = 'paths-default.csv'] {
    let local_statuses = open-local-configs
        | where status =~ '^update|ignore'
        | select full-path status

    open-configs $paths_file
    | join --left $local_statuses full-path
    | where status? != ignore
    | insert in-repo    {|r| $r.path-in-repo | path exists }
    | insert on-machine {|r| $r.full-path    | path exists }
}

# Filter expanded paths to the given module names (repo subdirs or exact files).
# Empty names = no filter. A name matching no tracked path fails fast — a typo
# would otherwise silently select nothing for it.
def select-modules [modules: list<string>] {
    let paths = $in
    if ($modules | is-empty) { return $paths }

    # Why: modules are typed as `path`, so file completion fills them in — and it
    # writes dirs as `nushell/` and may prefix `./`. Trim both to the bare repo path.
    let modules = $modules
        | str replace -r '^\./' ''
        | str trim --right --char '/'

    let selected = $paths | where {|r|
        $modules | any {|m| $r.path-in-repo == $m or ($r.path-in-repo | str starts-with $"($m)/") }
    }
    let unmatched = $modules | where {|m|
        not ($selected.path-in-repo | any { $in == $m or ($in | str starts-with $"($m)/") })
    }
    if ($unmatched | is-not-empty) {
        error make {msg: $"No tracked paths match: ($unmatched | str join ', ')"}
    }
    $selected
}

# Copy config files from the local machine into the repository
export def pull-from-machine [
    ...modules: path # limit pull to these repo subdirs or files (e.g. zellij helix/config.toml); omit for all
    --force # overwrite files with uncommitted changes
    --docker # use paths-docker.csv (pulling inside the sandbox VM)
] {
    let paths_file = if $docker { 'paths-docker.csv' } else { 'paths-default.csv' }
    let paths = expand-paths $paths_file | select-modules $modules | where on-machine

    if not $force and (check-dirty-files $paths path-in-repo "repo files") { return }

    $paths
    | group-by { $in.path-in-repo | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else { mkdir $dirname; $v }
    }
    | flatten
    | each { cp $in.full-path $in.path-in-repo }
}

# Show diff preview for a list of paths (repo → machine)
def show-push-diff [paths: table] {
    $paths | each {|row|
        if ($row.full-path | path exists) {
            let diff = ^git diff --no-index $row.full-path $row.path-in-repo | complete
            if ($diff.stdout | is-not-empty) {
                print $"\n=== ($row.full-path) ==="
                $diff.stdout | lines | skip 4 | str join (char newline) | print
            }
        } else {
            print $"\n=== ($row.full-path) ==="
            print $"(ansi yellow)→ NEW FILE will be created(ansi reset)"
            if not ($row.full-path | path dirname | path exists) {
                print $"(ansi yellow)  → parent directory will be created: ($row.full-path | path dirname)(ansi reset)"
            }
        }
    }
}

# Machine dir of the app a row belongs to: ~/.config/helix for helix/runtime/themes/x.toml
def app-root []: record -> string {
    let depth = $in.path-in-repo | path split | skip 1 | length
    $in.full-path | path split | drop $depth | path join
}

# Copy config files from the repository to the local machine
export def push-to-machine [
    ...modules: path # limit push to these repo subdirs or files (e.g. zellij helix/config.toml)
    --all # push every tracked config; without it, name the modules
    --create-dirs # also create a missing app dir (e.g. ~/.config/helix); subdirs inside an existing one are always created
    --dry-run # show diff of what would change without copying
    --docker # use paths-docker.csv for Docker sandbox setup
    --delete-orphans # remove machine files whose repo source was deleted
] {
    # Why: a bare push overwrote every tracked config, files nobody in the session touched included.
    if ($modules | is-empty) and not $all {
        error make --unspanned {msg: 'Name the modules to push (e.g. `toolkit push-to-machine zellij`), or pass --all to push every tracked config'}
    }
    let paths_file = if $docker { 'paths-docker.csv' } else { 'paths-default.csv' }
    let paths = expand-paths $paths_file | select-modules $modules
    let to_copy = $paths | where in-repo
    if ($to_copy.path-in-repo | any { $in == 'helix/config-no-wrap.toml' }) { check-no-wrap }
    let to_delete = if $delete_orphans {
        $paths | where {|r| (not $r.in-repo) and $r.on-machine }
    } else { [] }

    # Why: a missing subdir under an existing app dir (~/.config/helix/runtime/themes)
    # is only tracked content not pushed yet; a missing app dir may mean the app
    # does not live on this machine, so that one stays the user's call.
    # Checked before --dry-run returns, so the preview and the real run agree.
    let no_app_dir = $to_copy | where {|r| not ($r | app-root | path exists) }
    if not $create_dirs and ($no_app_dir | is-not-empty) {
        print $"(ansi red)Error: these files belong to app dirs missing on this machine:(ansi reset)"
        $no_app_dir | each {|r| print $"  ($r.full-path)" }
        print $"\nPass --create-dirs to create them, or name only the modules you want."
        return
    }

    # Why: the ~/.config commit names the dotfiles commit it deploys, which is only
    # true when the pushed files are committed here.
    let unsaved = if (source-is-repo) {
        dirty-paths (pwd) ($to_copy.path-in-repo ++ $to_delete.path-in-repo)
    } else { [] }
    if ($unsaved | is-not-empty) {
        error make --unspanned {msg: $"Commit these files in dotfiles before pushing them:\n  ($unsaved | path relative-to (pwd) | str join "\n  ")"}
    }

    let root = $config_root | path expand --no-symlink
    let in_root = {|r| $r.full-path | str starts-with $"($root)/" }
    if not $dry_run { ensure-config-repo $root ($paths | where $in_root | get full-path) }

    # A machine file that equals the repo, or equals HEAD in ~/.config (the last push),
    # is safe to overwrite; any other difference was made on the machine after the push.
    # Files outside ~/.config have no baseline and are overwritten as they are.
    let differs = $to_copy | where {|r|
        ($r.full-path | path exists) and ((open --raw $r.full-path | into binary) != (open --raw $r.path-in-repo | into binary))
    }
    let drift = if ($root | path join '.git' | path exists) {
        dirty-paths $root ($differs ++ $to_delete | where $in_root | get full-path)
    } else { [] }
    if ($drift | is-not-empty) {
        let pull = if $docker { 'toolkit pull-from-machine --docker' } else { 'toolkit pull-from-machine' }
        let rows = $differs ++ $to_delete | where full-path in $drift
        show-push-diff ($rows | where in-repo)
        error make --unspanned {msg: ([
            'These files changed on the machine after the last push, and dotfiles does not hold the change:'
            ...($rows | each {|r| $"  ($r.full-path)" })
            ''
            'Every change under the tracked ~/.config paths starts in the dotfiles repo, so find out where this one came from.'
            $"To keep it: `($pull) ($rows.path-in-repo | str join ' ')`, review and commit it in dotfiles, then push again."
            $"To drop it: `git -C ($root) checkout -- <file>`, or delete the file if git does not track it, then push again."
        ] | str join "\n")}
    }

    if $dry_run {
        show-push-diff $to_copy
        if ($to_delete | is-not-empty) {
            print $"\n(ansi yellow)Orphans to delete:(ansi reset)"
            $to_delete | get full-path | each { print $"  ($in)" }
        }
        return
    }

    $to_copy | get full-path | path dirname | uniq | where { not ($in | path exists) } | each { mkdir $in }
    $to_copy | each { cp $in.path-in-repo $in.full-path }

    $to_delete | each { rm $in.full-path }

    [
        [target link];
        ['~/.config/zellij/todo-nu/todo-hx.nu' '~/.local/bin/todo-hx']
        ['~/.config/zellij/hx-scrollback.nu' '~/.local/bin/hx-scrollback']
        ['~/.config/helix/hx-nu' '~/.local/bin/hx-nu'] # to execute nushell in the environment with chosen modules (if the file exist)
        ['~/.config/helix/hx-block' '~/.local/bin/hx-block'] # column-aware block writer, called by the `+ b` keybinding
        ['~/.config/helix/git-stage-lines' '~/.local/bin/git-stage-lines'] # stages the selected lines, called by the `+ h` keybinding
        ['~/.config/helix/hx-quote' '~/.local/bin/hx-quote'] # Claude Code's $EDITOR (settings.json), needs PATH: helix minus the `# ` quoting in the ctrl+x ctrl+e file
    ] | each {|s|
        let target = $s.target | path expand
        let link = $s.link | path expand --no-symlink
        if ($target | path exists) {
            mkdir ($link | path dirname)
            ^ln -sfn $target $link
        }
    }

    let pending = dirty-paths $root ($to_copy ++ $to_delete | where $in_root | get full-path)
    if ($pending | is-not-empty) {
        ^git -C $root add --all -- ...$pending
        ^git -C $root commit --quiet --message $"push-to-machine: dotfiles@(source-id)" -- ...$pending
    }
}

# helix/config-no-wrap.toml is helix/config.toml with soft-wrap off, for the Zellij
# scrollback editor. It stays a tracked file because push copies files from the repo.
def no-wrap-config []: nothing -> string {
    let src = open --raw helix/config.toml
    let flipped = $src | str replace "[editor.soft-wrap]\nenable = true" "[editor.soft-wrap]\nenable = false"
    if $flipped == $src {
        error make {msg: 'helix/config.toml: `enable = true` is not the first line of [editor.soft-wrap]'}
    }
    "# generated by `toolkit gen-no-wrap` (toolkit.nu) from config.toml; edit that file instead\n\n" + $flipped
}

# Write helix/config-no-wrap.toml from helix/config.toml.
export def gen-no-wrap [] {
    no-wrap-config | save --force helix/config-no-wrap.toml
}

# Why: the copy is edited by hand nowhere, so it only drifts when someone forgets to
# regenerate it; push is the last point before the drift reaches the machine.
def check-no-wrap [] {
    if (open --raw helix/config-no-wrap.toml) != (no-wrap-config) {
        error make {msg: 'helix/config-no-wrap.toml is out of date: run `nu --commands "use toolkit.nu; toolkit gen-no-wrap"` and commit it'}
    }
}

# Scan tracked directories for new config files and update paths-local.csv
export def fill-candidates [] {
    let configs = open-configs

    let local_configs = open-local-configs

    let ignored_paths = $local_configs
        | where status? == 'ignore'
        | where {|i| $i.full-path | path exists }
        | upsert path-type {|i| $i.full-path | path type }

    let ignored_folders = $ignored_paths
        | where path-type == 'dir'
        | get full-path

    let regex = '\.^$*+?{}()[]|/' | split chars | each { $'\($in)' } | str join '|' | $"\(($in))"

    let ignored_folders_regex = $ignored_folders
        | str replace --all --regex $regex '\$1'
        | str join '|'
        | $"^($in)"

    let candidates = $configs
        | get full-path
        | path dirname
        | where $it != $nu.home-dir
        | uniq
        | each {|dir| glob ($dir | path join '**/*') --no-dir --exclude $excluded_scan_globs }
        | flatten
        | if $ignored_folders_regex == '^' { } else {
            where $it !~ $ignored_folders_regex
        }
        | where $it not-in $configs.full-path
        | where ($it | path type) == 'file'
        | wrap full-path

    $local_configs
    | where full-path? !~ $ignored_folders_regex and status? not-in ['ignore']
    | prepend ($ignored_paths | select full-path status --optional)
    | append $candidates
    | uniq-by full-path
    | sort-by full-path
    | default '' status
    | save -f paths-local.csv
}

# List repo files not tracked in any paths-*.csv, optionally delete them
export def cleanup-paths-not-in-csv [
    --delete # git rm orphan files instead of just listing them
] {
    let exist_paths = glob **/* --exclude $excluded_locals --no-dir

    let paths_in_csv = glob paths-*.csv
        | each { open-configs $in | get path-in-repo }
        | flatten
        | uniq

    let orphans = $exist_paths | path relative-to (pwd) | where $it not-in $paths_in_csv

    if $delete and ($orphans | is-not-empty) {
        $orphans | each { ^git rm $in }
    } else {
        $orphans
    }
}
