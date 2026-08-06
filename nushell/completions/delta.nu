# Nushell completions for delta — a syntax-highlighting pager for git and diff output
# Built against delta 0.19.2. Flags come from `delta --help` of that build, and stay in that order so a version bump diffs cleanly.
#
# 29 of delta's 37 --*-style flags are deliberately absent. They are one-off colour tuning that belongs in gitconfig, not something anyone types at a prompt, and carrying them would bury the flags that change what delta actually does. The eight kept are the five diff-line styles people do set (minus, plus, zero, minus-emph, plus-emph) plus the three that accept 'omit' and so drop a whole section from the output (commit, file, hunk-header).

# delta marks every extension green in --list-languages, so this reads the colour markup rather than the column layout: the name column collapses to a single space for the longest names, and splitting on whitespace silently loses the extensions of "Bourne Again Shell (bash)" and nine others.
def "nu-complete delta languages" [] {
    let listed = (^delta --list-languages | complete)
    if $listed.exit_code != 0 { return [] }

    $listed.stdout | parse -r '\x1b\[32m(?<value>[^\x1b]+)\x1b\[0m' | get value | uniq
}

# Piped output is a plain "mode<tab>name" table, which is only true off a terminal — where a completer always runs.
def "nu-complete delta syntax themes" [] {
    let listed = (^delta --list-syntax-themes | complete)
    if $listed.exit_code != 0 { return [] }

    [{value: none description: "disable all syntax highlighting"}]
    | append ($listed.stdout | parse -r '(?m)^(?<description>\S+)\t(?<value>.+)$' | select value description)
}

# A delta theme is just a named feature in git config, and --show-themes renders demo diffs instead of listing names, so the names come from git config. Three-segment keys only: delta.<feature>.<option> is a feature, delta.<option> is the plain section.
def "nu-complete delta features" [] {
    let configured = (^git config --get-regexp '^delta\.' | complete)
    if $configured.exit_code != 0 { return [] }

    $configured.stdout | parse -r '(?m)^delta\.(?<value>.+)\.[^.\s]+\s' | get value | uniq
}

# --show-colors lists only the 140 CSS names, so the special colours and the attributes from the STYLES section have to be spelled out here. Left unsorted so the few words you actually type stay ahead of the CSS wall.
def "nu-complete delta styles" [] {
    let shown = (^delta --show-colors | complete)
    let css = if $shown.exit_code == 0 {
        $shown.stdout | ansi strip | parse -r 'color\(\): string \{ return "(?<value>[^"]+)"' | get value | uniq
    } else {
        []
    }

    {
        options: {sort: false}
        completions: [
            {value: auto description: "let delta pick the colour"}
            {value: normal description: "the terminal's own foreground or background"}
            {value: raw description: "pass the input's own colours through unchanged"}
            {value: syntax description: "syntax-highlight the text (foreground only)"}
            {value: omit description: "drop the element entirely (commit, file and hunk-header only)"}
            ...([blink bold dim hidden italic reverse strike ul underline] | each {|it| {value: $it description: "attribute"}})
            ...([black red green yellow blue magenta cyan white brightblack brightred brightgreen brightyellow brightblue brightmagenta brightcyan brightwhite] | each {|it| {value: $it description: "ansi colour"}})
            ...($css | each {|it| {value: $it description: "css colour"}})
        ]
    }
}

const auto_always_never = [auto always never]

const detect_dark_light = [
    {value: auto description: "query the terminal only when the output is not redirected"}
    {value: always description: "always query the terminal for its colours"}
    {value: never description: "never query the terminal for its colours"}
]

const grep_output_type = [
    {value: ripgrep description: "file name once, then its matching lines each with a line number"}
    {value: classic description: "file name:line number, then the matching line"}
]

const line_fill_method = [
    {value: ansi description: "extend the background with an ansi sequence (default)"}
    {value: spaces description: "pad with spaces (default when the output is not a terminal)"}
]

export extern main [
    minus_file?: path # first file to compare; `delta a b` is `diff -u a b | delta`
    plus_file?: path # second file to compare
    --blame-format: string # format of git blame commit metadata; {timestamp} {author} {commit}
    --blame-palette: string@"nu-complete delta styles" # space-separated background colours cycled over blame lines
    --blame-separator-format: string # separator between the blame metadata and the code; "none" turns line numbers off
    --blame-timestamp-format: string # strftime format delta expects in raw git blame output
    --blame-timestamp-output-format: string # strftime format for the timestamps delta prints
    --color-only # colour the hunk lines but leave the input structurally untouched
    --config: path # load this config file instead of ~/.gitconfig
    --commit-regex: string # regex identifying the commit line in git output
    --commit-style: string@"nu-complete delta styles" # style of the commit hash line; 'omit' removes it
    --dark # use the default colours for a dark terminal background
    --default-language: string@"nu-complete delta languages" # fallback language when it cannot be inferred from the filename; delta's own default is "txt", an extension, so extensions are what this offers
    --detect-dark-light: string@$detect_dark_light # ask the terminal for its colours; ignored under --dark or --light
    --diff-args (-@): string # extra arguments for the `git diff` delta runs over two files
    --diff-highlight # emulate diff-highlight
    --diff-so-fancy # emulate diff-so-fancy
    --diff-stat-align-width: int # width given to file paths in a diff stat section
    --features: string@"nu-complete delta features" # space-separated names of delta features to activate
    --file-added-label: string # text shown before an added file path
    --file-copied-label: string # text shown before a copied file path
    --file-modified-label: string # text shown before a modified file path
    --file-removed-label: string # text shown before a removed file path
    --file-renamed-label: string # text shown before a renamed file path
    --file-style: string@"nu-complete delta styles" # style of the file section; 'omit' removes it
    --file-transformation: string # sed-style command rewriting file paths for display
    --generate-completion: string@[bash elvish fish powershell zsh] # print a completion file for this shell
    --grep-output-type: string@$grep_output_type # grep output layout; defaults to ripgrep when `rg --json` is detected
    --grep-separator-symbol: string # separator after the path and line number in grep output; "keep" preserves grep's own
    --hunk-header-style: string@"nu-complete delta styles" # style of the hunk header; 'file' and 'line-number' add those parts, 'omit' removes it
    --hunk-label: string # text shown before a hunk header
    --hyperlinks # render commit hashes, file names and line numbers as terminal hyperlinks
    --hyperlinks-commit-link-format: string # url template for commit hyperlinks; {commit} is substituted
    --hyperlinks-file-link-format: string # url template for file hyperlinks; {path}, {line} and {host} are substituted
    --inspect-raw-lines: string@["true" "false"] # read ansi codes in raw git lines; "false" is the kill-switch for --color-moved
    --keep-plus-minus-markers # keep git's +/- prefix on added and removed lines
    --light # use the default colours for a light terminal background
    --line-buffer-size: int # how many nearby lines to buffer for within-line diffing
    --line-fill-method: string@$line_fill_method # how side-by-side mode fills the rest of the line
    --line-numbers (-n) # show line numbers beside the diff
    --line-numbers-left-format: string # contents of the left line-number column; {nm} is the minus line number
    --line-numbers-right-format: string # contents of the right line-number column; {np} is the plus line number
    --list-languages # list the supported languages and their file extensions
    --list-syntax-themes # list the available syntax-highlighting themes
    --map-styles: string # rewrite styles found in the input, e.g. 'bold purple => red "#eeeeee"'
    --max-line-distance: float # 0.0-1.0; how far apart two lines may be and still count as a changed pair
    --max-syntax-highlighting-length: int # stop highlighting a line after this many characters; 0 never stops
    --max-line-length: int # truncate lines longer than this; 0 never truncates
    --merge-conflict-begin-symbol: string # string repeated to mark the start of a merge conflict
    --merge-conflict-end-symbol: string # string repeated to mark the end of a merge conflict
    --minus-emph-style: string@"nu-complete delta styles" # style of the changed parts of a removed line
    --minus-style: string@"nu-complete delta styles" # style of removed lines
    --navigate # jump between files with n and N inside the pager
    --navigate-regex: string # regex defining where --navigate stops
    --no-gitconfig # ignore every delta setting in git config
    --pager: string # pager to use; overrides DELTA_PAGER and PAGER
    --paging: string@$auto_always_never # whether to page the output
    --parse-ansi # print the input's ansi escape sequences in readable form, to feed --map-styles
    --plus-emph-style: string@"nu-complete delta styles" # style of the changed parts of an added line
    --plus-style: string@"nu-complete delta styles" # style of added lines
    --raw # pass the input through untouched; intended for testing delta
    --relative-paths # print every file path relative to the current directory
    --right-arrow: string # text shown between the two paths of a changed file heading
    --show-colors # show the named colours delta accepts
    --show-config # show the active value of every delta option
    --show-syntax-themes # show an example diff in each syntax-highlighting theme
    --show-themes # show an example diff in each delta theme
    --side-by-side (-s) # show the diff in two columns
    --syntax-theme: string@"nu-complete delta syntax themes" # syntax-highlighting theme; defaults to BAT_THEME
    --tabs: int # spaces a tab is replaced with; 0 passes tabs through
    --true-color: string@$auto_always_never # whether to emit 24-bit rgb colour codes
    --width (-w): string@[variable] # width of the decorations: a number, an offset like "-2", an expression like "74-2", or "variable"
    --word-diff-regex: string # regex defining a word for the within-line diff
    --wrap-left-symbol: string # symbol ending a line whose wrapped remainder is left-aligned
    --wrap-max-lines: string@[unlimited] # how often one line may wrap; 0 never wraps
    --wrap-right-percent: float # below this percentage of the width, wrapped content is right-aligned
    --wrap-right-prefix-symbol: string # symbol shown before right-aligned wrapped content
    --wrap-right-symbol: string # symbol ending a line whose wrapped remainder is right-aligned
    --zero-style: string@"nu-complete delta styles" # style of unchanged lines
    --24-bit-color: string@$auto_always_never # deprecated, use --true-color
    --version (-V) # print version
]
