# Nushell completions for fd - a fast and user-friendly alternative to find

def "nu-complete fd type" [] {
    [
        {value: "f" description: "regular files"}
        {value: "file" description: "regular files"}
        {value: "d" description: "directories"}
        {value: "dir" description: "directories"}
        {value: "directory" description: "directories"}
        {value: "l" description: "symbolic links"}
        {value: "symlink" description: "symbolic links"}
        {value: "s" description: "socket"}
        {value: "socket" description: "socket"}
        {value: "p" description: "named pipe (FIFO)"}
        {value: "pipe" description: "named pipe (FIFO)"}
        {value: "b" description: "block device"}
        {value: "block-device" description: "block device"}
        {value: "c" description: "character device"}
        {value: "char-device" description: "character device"}
        {value: "x" description: "executables"}
        {value: "executable" description: "executables"}
        {value: "e" description: "empty files or directories"}
        {value: "empty" description: "empty files or directories"}
    ]
}

def "nu-complete fd color" [] {
    [
        {value: "auto" description: "show colors if output is an interactive console (default)"}
        {value: "always" description: "always use colorized output"}
        {value: "never" description: "do not use colorized output"}
    ]
}

def "nu-complete fd hyperlink" [] {
    [
        {value: "auto" description: "use hyperlinks only if color is enabled"}
        {value: "always" description: "always use hyperlinks when printing file paths"}
        {value: "never" description: "never use hyperlinks"}
    ]
}

def "nu-complete fd strip-cwd-prefix" [] {
    [
        {value: "auto" description: "use the default behavior"}
        {value: "always" description: "always strip the ./ at the beginning of paths"}
        {value: "never" description: "never strip the ./"}
    ]
}

# Main extern definition
export extern main [
    pattern?: string # Search pattern (regex by default, glob with --glob)
    ...paths: path # Directories to search (default: current directory)
    --hidden (-H) # Include hidden directories and files
    --no-ignore (-I) # Show results ignored by .gitignore/.ignore/.fdignore
    --no-ignore-vcs # Show results ignored by .gitignore files
    --no-require-git # Respect gitignore rules even outside a git repository
    --no-ignore-parent # Show results ignored by parent-directory ignore files
    --unrestricted (-u) # Unrestricted search (alias for --no-ignore --hidden)
    --case-sensitive (-s) # Perform a case-sensitive search
    --ignore-case (-i) # Perform a case-insensitive search
    --glob (-g) # Glob-based search instead of regular expression
    --regex # Regular-expression based search (default)
    --fixed-strings (-F) # Treat the pattern as a literal string
    --and: string # Additional required search pattern (repeatable)
    --absolute-path (-a) # Show absolute paths instead of relative ones
    --list-details (-l) # Detailed listing format like 'ls -l'
    --follow (-L) # Traverse symbolic links
    --full-path (-p) # Match pattern against the full path
    --print0 (-0) # Separate results by the null character
    --max-depth (-d): int # Limit directory traversal to a given depth
    --min-depth: int # Only show results starting at the given depth
    --exact-depth: int # Only show results at the exact given depth
    --exclude (-E): string # Exclude files/directories matching the glob (repeatable)
    --prune # Do not traverse into directories that match
    --type (-t): string@"nu-complete fd type" # Filter by entry type (repeatable)
    --extension (-e): string # Filter by file extension (repeatable)
    --size (-S): string # Limit by file size, format <+-><NUM><UNIT>
    --changed-within: string # Files modified within a duration or since a date
    --changed-before: string # Files modified before a duration or date
    --owner (-o): string # Filter by user and/or group [(user|uid)][:(group|gid)]
    --format: string # Print results according to template
    --exec (-x): string # Execute a command for each result in parallel
    --exec-batch (-X): string # Execute the command once with all results
    --batch-size: int # Max number of arguments to pass to -X
    --ignore-file: path # Add a custom ignore-file in .gitignore format
    --color (-c): string@"nu-complete fd color" # When to use colorized output
    --hyperlink: string@"nu-complete fd hyperlink" # Add terminal hyperlinks to output paths
    --ignore-contain: string # Ignore directories containing the named entry
    --threads (-j): int # Number of threads for searching & executing
    --max-results: int # Limit the number of results and quit
    -1 # Limit the search to a single result (alias for --max-results=1)
    --quiet (-q) # Print nothing; exit 0 if there is at least one match
    --show-errors # Display filesystem errors (permissions, dead symlinks)
    --base-directory (-C): path # Change fd's working directory to the given path
    --path-separator: string # Path separator to use when printing paths
    --search-path: path # Search path as alternative to positional arg (repeatable)
    --strip-cwd-prefix: string@"nu-complete fd strip-cwd-prefix" # Control stripping of ./ prefix
    --one-file-system # Do not descend into a different file system
    --version (-V) # Print version
]
