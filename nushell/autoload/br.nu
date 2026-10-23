# Launch broot
#
# Examples:
#   > br -hi some/path
#   > br
#   > br -sdp
#   > br -hi -c "vacheblan.svg;:open_preview" ..
#
# See https://dystroy.org/broot/install-br/
export def --env br [
    --cmd (-c): string # Semicolon separated commands to execute
    --color: string = "auto" # Whether to have styles and colors (auto is default and usually OK) [possible values: auto, yes, no]
    --conf: string # Semicolon separated paths to specific config files"),
    --dates (-d) # Show the last modified date of files and directories"
    --no-dates (-D) # Don't show the last modified date"
    --only-folders (-f) # Only show folders
    --no-only-folders (-F) # Show folders and files alike
    --show-git-info (-g) # Show git statuses on files and stats on repo
    --no-show-git-info (-G) # Don't show git statuses on files and stats on repo
    --git-status # Only show files having an interesting git status, including hidden ones
    --hidden (-h) # Show hidden files
    --no-hidden (-H) # Don't show hidden files
    --height: int # Height (if you don't want to fill the screen or for file export)
    --help # Print help information
    --git-ignored (-i) # Show git ignored files
    --no-git-ignored (-I) # Don't show git ignored files
    --install # Install or reinstall the br shell function
    --no-sort # Don't sort
    --permissions (-p) # Show permissions
    --no-permissions (-P) # Don't show permissions
    --print-shell-function: string # Print to stdout the br function for a given shell
    --sizes (-s) # Show the size of files and directories
    --no-sizes (-S) # Don't show sizes
    --set-install-state: path # Where to write the produced cmd (if any) [possible values: undefined, refused, installed]
    --show-root-fs # Show filesystem info on top
    --max-depth: int # Only show trees up to a certain depth
    --sort-by-count # Sort by count (only show one level of the tree)
    --sort-by-date # Sort by date (only show one level of the tree)
    --sort-by-size # Sort by size (only show one level of the tree)
    --sort-by-type # Same as sort-by-type-dirs-first
    --sort-by-type-dirs-first # Sort by type, directories first (only show one level of the tree)
    --sort-by-type-dirs-last # Sort by type, directories last (only show one level of the tree)
    --trim-root (-t) # Trim the root too and don't show a scrollbar
    --no-trim-root (-T) # Don't trim the root level, show a scrollbar
    --version (-V) # Print version information
    --whale-spotting (-w) # Sort by size, show ignored and hidden files
    --write-default-conf: path # Write default conf files in given directory
    file?: path # Root Directory
]: nothing -> nothing {
    let args = [[on arg];
        [($cmd != null) $'--cmd=($cmd)']
        [($color != null) $'--color=($color)']
        [($conf != null) $'--conf=($conf)']
        [$dates --dates]
        [$no_dates --no-dates]
        [$only_folders --only-folders]
        [$no_only_folders --no-only-folders]
        [$show_git_info --show-git-info]
        [$no_show_git_info --no-show-git-info]
        [$git_status --git-status]
        [$hidden --hidden]
        [$no_hidden --no-hidden]
        [($height != null) $'--height=($height)']
        [$help --help]
        [$git_ignored --git-ignored]
        [$no_git_ignored --no-git-ignored]
        [$install --install]
        [$no_sort --no-sort]
        [$permissions --permissions]
        [$no_permissions --no-permissions]
        [($print_shell_function != null) $'--print-shell-function=($print_shell_function)']
        [$sizes --sizes]
        [$no_sizes --no-sizes]
        [($set_install_state != null) $'--set-install-state=($set_install_state)']
        [$show_root_fs --show-root-fs]
        [($max_depth != null) $'--max-depth=($max_depth)']
        [$sort_by_count --sort-by-count]
        [$sort_by_date --sort-by-date]
        [$sort_by_size --sort-by-size]
        [$sort_by_type --sort-by-type]
        [$sort_by_type_dirs_first --sort-by-type-dirs-first]
        [$sort_by_type_dirs_last --sort-by-type-dirs-last]
        [$trim_root --trim-root]
        [$no_trim_root --no-trim-root]
        [$version --version]
        [$whale_spotting --whale-spotting]
        [($write_default_conf != null) $'--write-default-conf=($write_default_conf)']
    ]
        | where $it.on
        | get arg

    let cmd_file = (
        if ($env.XDG_RUNTIME_DIR? | is-not-empty) { $env.XDG_RUNTIME_DIR } else { $nu.temp-dir }
        | path join $"broot-(random chars).tmp"
    )

    touch $cmd_file
    if ($file == null) {
        ^broot --outcmd $cmd_file ...$args
    } else {
        ^broot --outcmd $cmd_file ...$args $file
    }
    let out = open $cmd_file | str trim --char (char nl)

    rm -p -f $cmd_file

    if ($out | is-not-empty) {
        commandline edit --accept $out
    }
}

export extern broot [
    --cmd (-c): string # Semicolon separated commands to execute
    --color: string = "auto" # Whether to have styles and colors (auto is default and usually OK) [possible values: auto, yes, no]
    --conf: string # Semicolon separated paths to specific config files"),
    --dates (-d) # Show the last modified date of files and directories"
    --no-dates (-D) # Don't show the last modified date"
    --only-folders (-f) # Only show folders
    --no-only-folders (-F) # Show folders and files alike
    --show-git-info (-g) # Show git statuses on files and stats on repo
    --no-show-git-info (-G) # Don't show git statuses on files and stats on repo
    --git-status # Only show files having an interesting git status, including hidden ones
    --hidden (-h) # Show hidden files
    --no-hidden (-H) # Don't show hidden files
    --height: int # Height (if you don't want to fill the screen or for file export)
    --help # Print help information
    --git-ignored (-i) # Show git ignored files
    --no-git-ignored (-I) # Don't show git ignored files
    --install # Install or reinstall the br shell function
    --no-sort # Don't sort
    --outcmd: path # Write cd command in given path
    --permissions (-p) # Show permissions
    --no-permissions (-P) # Don't show permissions
    --print-shell-function: string # Print to stdout the br function for a given shell
    --sizes (-s) # Show the size of files and directories
    --no-sizes (-S) # Don't show sizes
    --set-install-state: path # Where to write the produced cmd (if any) [possible values: undefined, refused, installed]
    --show-root-fs # Show filesystem info on top
    --max-depth: int # Only show trees up to a certain depth
    --sort-by-count # Sort by count (only show one level of the tree)
    --sort-by-date # Sort by date (only show one level of the tree)
    --sort-by-size # Sort by size (only show one level of the tree)
    --sort-by-type # Same as sort-by-type-dirs-first
    --sort-by-type-dirs-first # Sort by type, directories first (only show one level of the tree)
    --sort-by-type-dirs-last # Sort by type, directories last (only show one level of the tree)
    --trim-root (-t) # Trim the root too and don't show a scrollbar
    --no-trim-root (-T) # Don't trim the root level, show a scrollbar
    --version (-V) # Print version information
    --whale-spotting (-w) # Sort by size, show ignored and hidden files
    --write-default-conf: path # Write default conf files in given directory
    file?: path # Root Directory
]
