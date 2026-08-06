# Nushell completions for bat 0.26.1 - a cat(1) clone with syntax highlighting and Git integration

# Why ^bat: bare `bat` would resolve to the extern below and never reach the binary.
def "nu-complete bat themes" [] {
    ^bat --list-themes | lines | where $it != ""
}

# --theme also accepts five special values that no --list-themes line reports, so they are spelled out here.
def "nu-complete bat theme" [] {
    {
        options: {sort: false}
        completions: (
            [
                {value: "auto" description: "pick a dark or light theme from the terminal colors (default)"}
                {value: "auto:always" description: "detect terminal colors even when output is redirected"}
                {value: "auto:system" description: "detect the color scheme from the system preference (macOS only)"}
                {value: "dark" description: "use the theme set by --theme-dark"}
                {value: "light" description: "use the theme set by --theme-light"}
            ]
            | append (nu-complete bat themes | each {|theme| {value: $theme description: ""} })
        )
    }
}

# Each --list-languages line is `name:ext1,ext2`; the extensions are what a user actually recognizes, so they become the description.
def "nu-complete bat languages" [] {
    ^bat --list-languages
    | lines
    | split column --number 2 ":" value description
}

def "nu-complete bat style components" [] {
    [
        {value: "default" description: "recommended style components (default)"}
        {value: "full" description: "all available components"}
        {value: "auto" description: "same as default, unless the output is piped"}
        {value: "plain" description: "no components at all"}
        {value: "changes" description: "Git modification markers"}
        {value: "header" description: "alias for header-filename"}
        {value: "header-filename" description: "filenames before the content"}
        {value: "header-filesize" description: "file sizes before the content"}
        {value: "grid" description: "lines separating the side bar and header from the content"}
        {value: "rule" description: "horizontal lines between files"}
        {value: "numbers" description: "line numbers in the side bar"}
        {value: "snip" description: "separation lines between distinct line ranges"}
    ]
}

# --style is one comma-separated token, so a suggestion has to carry the components already typed - nushell filters candidates against the whole token, and a bare component name would not match `numbers,gr`.
def "nu-complete bat style" [context: string] {
    let typed = $context | split row " " | last | str replace --regex '^--style=' ''
    let done = $typed | split row "," | drop 1
    let prefix = if ($done | is-empty) { "" } else { ($done | str join ",") + "," }

    {
        options: {sort: false}
        completions: (
            nu-complete bat style components
            | where value not-in $done
            | each {|it| {value: $"($prefix)($it.value)" description: $it.description} }
        )
    }
}

export extern main [
    ...files: path # File(s) to print / concatenate; a dash or no argument reads from stdin
    --show-all (-A) # Show non-printable characters like space, tab or newline
    --nonprintable-notation: string@[unicode caret] # Notation for non-printable characters
    --binary: string@["no-printing" "as-text"] # How to treat binary content (default: no-printing)
    --plain (-p) # Only plain style, no decorations (alias for --style=plain); -pp also disables paging
    --language (-l): string@"nu-complete bat languages" # Set the language for syntax highlighting
    --highlight-line (-H): string # Highlight the given line ranges, e.g. 40, 30:40, :40, 40:, 30:+10
    --file-name: string # Name to display for a file; also used for syntax detection
    --diff (-d) # Only show lines added/removed/modified against the Git index
    --diff-context: int # Lines of context around changed lines when using --diff
    --tabs: int # Tab width in spaces; 0 passes tabs through directly
    --wrap: string@[auto never character] # Text-wrapping mode
    --chop-long-lines (-S) # Truncate lines longer than screen width (alias for --wrap=never)
    --terminal-width: string # Terminal width; a leading + or - makes it an offset
    --number (-n) # Only line numbers, no other decorations (alias for --style=numbers)
    --color: string@[auto never always] # When to use colored output
    --italic-text: string@[always never] # When to use ANSI sequences for italic text
    --decorations: string@[auto never always] # When to use the decorations set via --style
    --force-colorization (-f) # Alias for --decorations=always --color=always
    --paging: string@[auto never always] # When to use the pager
    --pager: string # Which pager to use; overrides PAGER and BAT_PAGER
    --map-syntax (-m): string # Map a glob pattern to a syntax name, e.g. '*.build:Python'
    --ignored-suffix: string # Extension to ignore when detecting syntax, e.g. '.dev'
    --theme: string@"nu-complete bat theme" # Theme for syntax highlighting
    --theme-light: string@"nu-complete bat themes" # Theme used when the terminal has a light background
    --theme-dark: string@"nu-complete bat themes" # Theme used when the terminal has a dark background
    --list-themes # Display the list of supported themes
    --squeeze-blank (-s) # Squeeze consecutive empty lines into a single one
    --squeeze-limit: int # Maximum number of consecutive empty lines to print
    --strip-ansi: string@[auto always never] # When to strip ANSI escape sequences from the input
    --style: string@"nu-complete bat style" # Comma-separated components or a pre-defined style; a set of all +/- prefixed components modifies the previous set instead of replacing it
    --line-range (-r): string # Only print the given line range, e.g. 30:40, :40, 40:, -10:, 30:40:2
    --list-languages (-L) # Display the list of supported languages
    --unbuffered (-u) # Accepted for POSIX compliance and ignored
    --completion: string@[bash fish zsh ps1] # Show shell completion for a certain shell
    --diagnostic # Show diagnostic information for bug reports
    --acknowledgements # Show acknowledgements
    --set-terminal-title # Set the terminal title to filenames when using a pager
    --version (-V) # Print version
    # bat's own -h/--help is deliberately not declared: nushell intercepts a declared --help and prints this signature instead of running the binary, so `bat --help` would stop showing bat's real help. A completion file must not change what the command does.
]
