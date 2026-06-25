# Dotfiles synchronization toolkit
#
# Manages syncing configuration files between this Git repository and the local machine.
# Uses two CSV files for configuration:
#   - paths-default.csv: Single column (full-path) with glob patterns. Repo paths are derived:
#     ~/.config/X/... → X/...  |  ~/.X/... → X/...
#   - paths-local.csv: Optional local overrides with status column (update, ignore)
#
# Commands:
#   pull-from-machine        - Copy configs from machine into repo
#   push-to-machine          - Copy configs from repo to machine (--dry-run for preview)
#   fill-candidates          - Find new config files to potentially track
#   cleanup-paths-not-in-csv - List repo files not tracked in CSV
#   install-skills           - Deploy Claude skills from sibling skill repos into ~/.claude/skills/

const excluded_locals = [**/.git/** **/.jj/** toolkit.nu macos-fresh/* paths-default.csv paths-docker.csv README.md .gitignore CLAUDE.md .DS_Store .claude/settings.local.json paths-local.csv]

# Structural runtime/state/secret paths Claude Code (and git) create under tracked
# config roots on every machine — never hand-authored config. Patterns are
# base-relative: glob --exclude matches them against each scanned parent dir.
# Why: ~/.claude/CLAUDE.md sits at the .claude root, so the scan walks ~/.claude/**,
# which is ~99% session/plugin/history files (thousands) plus the credentials secret.
# Not paths-local `ignore` rows because: these are universal, not per-machine choices —
# fail-fast keeps the structural invariant here and the per-user exceptions there.
const excluded_scan_globs = [
    .git/** backups/** cache/** claudemd-eval-workspace/** downloads/**
    file-history/** paste-cache/** plugins/** projects/** session-env/**
    sessions/** shell-snapshots/** statsig/** tasks/** todos/**
    .credentials.json history.* .last-cleanup .last-update-result.json
]

const commit_target_dirs = [~/.config ~/.claude]

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
        print $"\nCommit or stash changes first, or use --commit-existing / --force to overwrite."
        true
    } else {
        false
    }
}

# Commit the given files in whatever git repo contains each, grouped by repo root.
# Why: lets push-to-machine snapshot the machine's current config before it
# overwrites it, so the prior state stays recoverable in git history instead of
# being lost. Commits each file with an explicit pathspec, so unrelated dirty
# files in the same repo are left untouched.
# Contract: caller passes only in-repo files (filtered via has-uncommitted-changes),
# so every group has a non-empty repo root and something to commit.
def commit-in-own-repo [files: list<path> message: string] {
    $files
    | group-by {|f| do { cd ($f | path dirname); ^git rev-parse --show-toplevel } | complete | get stdout | str trim }
    | items {|toplevel group|
        ^git -C $toplevel add ...$group
        ^git -C $toplevel commit -m $message -- ...$group
    }
}

# Ensure each config target dir exists and is a git repo. Idempotent — a no-op
# for dirs that are already repos. Without --create-dirs, a missing dir is skipped.
def init-target-repos [create_dirs: bool] {
    $commit_target_dirs | each {|target_dir|
        let target_dir = $target_dir | path expand --no-symlink
        if not ($target_dir | path exists) {
            if $create_dirs { mkdir $target_dir } else { return }
        }
        if not ($target_dir | path join '.git' | path exists) { ^git init $target_dir }
    }
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

# Copy config files from the local machine into the repository
export def pull-from-machine [
    --force # overwrite files with uncommitted changes
] {
    let paths = expand-paths | where on-machine

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
                print $"(ansi red)  ⚠ Parent directory does not exist: ($row.full-path | path dirname)(ansi reset)"
            }
        }
    }
}

# Copy config files from the repository to the local machine
export def push-to-machine [
    --create-dirs # in case of missing directories - create them in place
    --force # overwrite files with uncommitted changes
    --commit-existing # snapshot dirty destination/orphan files in git before pushing (instead of erroring)
    --dry-run # show diff of what would change without copying
    --docker # use paths-docker.csv for Docker sandbox setup
    --commit-changes # git add + commit in target directories after push
    --delete-orphans # remove machine files whose repo source was deleted
] {
    let paths_file = if $docker { 'paths-docker.csv' } else { 'paths-default.csv' }
    let paths = expand-paths $paths_file
    let to_copy = $paths | where in-repo
    let to_delete = if $delete_orphans {
        $paths | where {|r| (not $r.in-repo) and $r.on-machine }
    } else { [] }

    if $dry_run {
        show-push-diff $to_copy
        if ($to_delete | is-not-empty) {
            print $"\n(ansi yellow)Orphans to delete:(ansi reset)"
            $to_delete | get full-path | each { print $"  ($in)" }
        }
        return
    }

    if $commit_existing {
        # Why: on a fresh machine the target dirs aren't git repos yet, so their
        # pre-existing files wouldn't register as "uncommitted" and would be lost
        # on overwrite. Init first — then those files count as untracked and get
        # snapshotted below, before we copy over them.
        init-target-repos $create_dirs
        let dirty = $to_copy | append $to_delete
            | get full-path
            | where { has-uncommitted-changes $in }
        if ($dirty | is-not-empty) {
            commit-in-own-repo $dirty "push-to-machine: snapshot before overwrite"
        }
    } else {
        if not $force and (check-dirty-files $to_copy full-path "destination files") { return }
        if not $force and (check-dirty-files $to_delete full-path "orphans") { return }
    }

    $to_copy
    | group-by { $in.full-path | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else {
            if $create_dirs { mkdir $dirname; $v }
        }
    }
    | compact
    | flatten
    | each { cp $in.path-in-repo $in.full-path }

    $to_delete | each { rm $in.full-path }

    [
        [target link];
        ['~/.config/zellij/todo-nu/todo-hx.nu' '~/.local/bin/todo-hx']
        ['~/.config/zellij/hx-scrollback.nu' '~/.local/bin/hx-scrollback']
        ['~/.config/helix/hx-nu' '~/.local/bin/hx-nu'] # to execute nushell in the environment with chosen modules (if the file exist)
        ['~/.config/helix/hx-block' '~/.local/bin/hx-block'] # column-aware block writer, called by the `+ b` keybinding
    ] | each {|s|
        let target = $s.target | path expand
        let link = $s.link | path expand --no-symlink
        if ($target | path exists) {
            mkdir ($link | path dirname)
            ^ln -sfn $target $link
        }
    }

    # Initialize git repos for config directories (idempotent if --commit-existing already did)
    init-target-repos $create_dirs

    if $commit_changes {
        $commit_target_dirs | each {|target_dir|
            let target_dir = $target_dir | path expand --no-symlink
            if not ($target_dir | path join '.git' | path exists) { return }

            let touched_files = $to_copy | get full-path
                | append ($to_delete | get full-path)
                | where { $in | str starts-with $"($target_dir)/" }

            if ($touched_files | is-empty) { return }

            $touched_files | each { ^git -C $target_dir add $in }
            ^git -C $target_dir diff --cached --quiet ...$touched_files
            | complete
            | if $in.exit_code != 0 {
                ^git -C $target_dir commit -m "push-to-machine" -- ...$touched_files
            }
        }
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

const this_dir = path self | path dirname

const skill_repos = [
    [repo subpath];
    [my-claude-skills plugins]
    [nushell-skills plugins]
]

# Collect all available skills from sibling skill repos
def collect-skills [base: path] {
    $skill_repos | each {|r|
        let repo_dir = $base | path join $r.repo
        if not ($repo_dir | path exists) {
            print $"(ansi yellow)Skipped:(ansi reset) ($r.repo) not found at ($repo_dir)"
            return []
        }

        let src = $repo_dir | path join $r.subpath

        # subpath ending in 'skills': flat — skills/* are skill dirs directly
        # subpath 'plugins': nested — plugins/*/skills/* are skill dirs (every plugin)
        let skill_dirs = if ($r.subpath | str ends-with 'skills') {
            ls $src | where type == dir | get name
        } else {
            glob ($src | path join '*/skills/*') --no-file
        }

        $skill_dirs | each {|s| {name: ($s | path basename) path: $s repo: $r.repo} }
    } | flatten
}

# Deploy Claude skills from sibling repos into ~/.claude/skills/
# Expects my-claude-skills and nushell-skills as siblings of this repo (../my-claude-skills, etc.)
export def install-skills [
    ...names: string # skill names to install (omit for --all, or use --list to see available)
    --base-dir: path # directory containing skill repos (default: parent of this repo)
    --all # install all available skills
    --list # list available skills without installing
    --dry-run # show what would be copied without copying
] {
    let base = $base_dir | default ($this_dir | path join '..')
    let skills = collect-skills $base

    if $list {
        return ($skills | select name repo)
    }

    if ($names | is-empty) and not $all {
        print "Specify skill names, or use --all to install everything."
        print $"Use --list to see available skills."
        return
    }

    let to_install = if $all {
        $skills
    } else {
        let unknown = $names | where {|n| $n not-in $skills.name }
        if ($unknown | is-not-empty) {
            print $"(ansi red)Unknown skills:(ansi reset) ($unknown | str join ', ')"
            return
        }
        # When a skill exists in both repos, keep the last occurrence
        # Not: nushell-skills is listed after my-claude-skills in skill_repos,
        # so its version wins for shared skills
        $skills | where name in $names
    }

    let target = '~/.claude/skills' | path expand --no-symlink
    if not $dry_run { mkdir $target }

    # Deduplicate: last occurrence wins (nushell-skills over my-claude-skills)
    let to_install = $to_install | reverse | uniq-by name | reverse

    for $skill in $to_install {
        if $dry_run {
            print $"($skill.repo) → ($skill.name)"
        } else {
            let dest = $target | path join $skill.name
            mkdir $dest
            ^rsync -a --delete $"($skill.path)/" $"($dest)/"
            print $"(ansi green)Installed:(ansi reset) ($skill.name) \(($skill.repo))"
        }
    }
}
