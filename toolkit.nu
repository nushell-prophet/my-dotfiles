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
def check-dirty-files [paths: table, field: string, context: string] {
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

# Merge local and default configs, applying ignore/update status and deduplication
def assemble-paths [paths_file: string = 'paths-default.csv'] {
    let local_statuses = open-local-configs
    | where status =~ '^update|ignore'
    | select full-path status

    open-configs $paths_file
    | join --left $local_statuses full-path
    | where status? != ignore
}

# Copy config files from the local machine into the repository
export def pull-from-machine [
    --force # overwrite files with uncommitted changes
] {
    let paths = assemble-paths
    | where {|i| $i.full-path | path exists }

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
    --dry-run # show diff of what would change without copying
    --docker # use paths-docker.csv for Docker sandbox setup
    --commit-changes # git add + commit in target directories after push
] {
    let paths_file = if $docker { 'paths-docker.csv' } else { 'paths-default.csv' }
    let paths = assemble-paths $paths_file
    | where {|i| $i.path-in-repo | path exists }

    if $dry_run {
        show-push-diff $paths
        return
    }

    if not $force and (check-dirty-files $paths full-path "destination files") { return }

    $paths
    | group-by { $in.full-path | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else {
            if $create_dirs { mkdir $dirname; $v }
        }
    }
    | compact
    | flatten
    | each { cp $in.path-in-repo $in.full-path }

    # Create symlinks for PATH-accessible commands
    [[target link];
     ['~/.config/zellij/todo-nu/todo-hx.nu' '~/.local/bin/todo-hx']
     ['~/.config/zellij/hx-scrollback.nu' '~/.local/bin/hx-scrollback']
    ] | each {|s|
        let target = $s.target | path expand
        let link = $s.link | path expand --no-symlink
        if ($target | path exists) {
            mkdir ($link | path dirname)
            ^ln -sfn $target $link
        }
    }

    # Initialize git repos for config directories
    $commit_target_dirs | each {|target_dir|
        let target_dir = $target_dir | path expand --no-symlink
        if not ($target_dir | path exists) {
            if $create_dirs { mkdir $target_dir } else { return }
        }
        if not ($target_dir | path join '.git' | path exists) { ^git init $target_dir }
    }

    if $commit_changes {
        $commit_target_dirs | each {|target_dir|
            let target_dir = $target_dir | path expand --no-symlink
            if not ($target_dir | path join '.git' | path exists) { return }

            let pushed_files = $paths
            | where { $in.full-path | str starts-with $"($target_dir)/" }
            | get full-path

            if ($pushed_files | is-empty) { return }

            $pushed_files | each { ^git -C $target_dir add $in }
            ^git -C $target_dir diff --cached --quiet ...$pushed_files
            | complete
            | if $in.exit_code != 0 {
                ^git -C $target_dir commit -m "push-to-machine" -- ...$pushed_files
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
    | each {
        path join '**/*'
        | into glob
        | try { ls $in | get name --optional }
    }
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
    [my-claude-skills plugins/my-skills/skills]
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

        # my-claude-skills: flat — skills/* are skill dirs directly
        # nushell-skills: nested — plugins/*/skills/* are skill dirs
        let skill_dirs = if ($r.subpath | str ends-with 'skills') {
            ls $src | where type == dir | get name
        } else {
            glob ($src | path join '*/skills/*') --no-file
        }

        $skill_dirs | each {|s| {name: ($s | path basename), path: $s, repo: $r.repo} }
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
