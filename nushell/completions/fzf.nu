# Nushell completions for fzf 0.74.0 - an interactive fuzzy filter for any kind of list.
# Flags come from `fzf --help`; the key, event and action names come from `fzf --man`.

# Why: nushell matches a candidate against the whole word under the cursor, so a completer for a comma-joined fzf value has to re-emit the part already typed, and it needs to know which separator it stopped at.
def "nu-complete fzf split" [context: string, seps: list<string>] {
    let word = $context | split row " " | last | str replace -r '^[\x27"]' ''
    let cut = $seps | each {|s| $word | str index-of --end $s } | math max

    if $cut < 0 {
        {head: "", sep: ""}
    } else {
        {head: ($word | str substring ..$cut), sep: ($word | str substring $cut..$cut)}
    }
}

# Why: fzf's own error message enumerates the same 16 styles for every *-border flag, while --help prints a different abridged subset next to each one.
const border_styles = [
    rounded sharp bold block thinblock double dashed horizontal
    vertical top bottom left right line inline none
]

def "nu-complete fzf style" [context: string] {
    let at = nu-complete fzf split $context [":"]

    if $at.sep == ":" {
        $border_styles | each {|s| $"($at.head)($s)" }
    } else {
        [
            {value: "default", description: "the classic fzf look"}
            {value: "minimal", description: "no borders, no scrollbar, no separator"}
            {value: "full", description: "bordered sections; suffix with :BORDER_STYLE"}
        ]
    }
}

def "nu-complete fzf tiebreak" [context: string] {
    let at = nu-complete fzf split $context [","]

    [
        {value: "length", description: "prefer the shorter line (default)"}
        {value: "chunk", description: "prefer the line with the shorter matched chunk"}
        {value: "pathname", description: "prefer a match in the file name over one in the directory"}
        {value: "begin", description: "prefer a match closer to the start of the line"}
        {value: "end", description: "prefer a match closer to the end of the line"}
        {value: "index", description: "prefer the line that came first in the input"}
    ]
    | update value {|r| $"($at.head)($r.value)" }
}

def "nu-complete fzf walker" [context: string] {
    let at = nu-complete fzf split $context [","]

    [
        {value: "file", description: "list files"}
        {value: "dir", description: "list directories"}
        {value: "follow", description: "follow symbolic links"}
        {value: "hidden", description: "include hidden entries"}
    ]
    | update value {|r| $"($at.head)($r.value)" }
}

def "nu-complete fzf preview-window" [context: string] {
    let at = nu-complete fzf split $context [","]

    [
        up down left right next
        wrap nowrap wrap-word nowrap-word
        cycle nocycle follow nofollow info noinfo hidden nohidden
        default
        ...($border_styles | each {|s| $"border-($s)" })
    ]
    | each {|v| $"($at.head)($v)" }
}

const color_base_schemes = [dark light base16 16 bw]

const color_names = [
    fg list-fg selected-fg preview-fg
    bg list-bg selected-bg preview-bg input-bg header-bg footer-bg
    hl selected-hl
    current-fg fg+ current-bg bg+ gutter current-hl hl+
    alt-bg alt-gutter
    query input-fg ghost disabled
    info
    border list-border scrollbar separator gap-line
    preview-border preview-scrollbar input-border header-border footer-border
    label list-label preview-label input-label header-label footer-label
    prompt pointer marker spinner
    header header-fg footer footer-fg
    nth nomatch
]

const color_values = [
    -1
    black red green yellow blue magenta cyan white
    bright-black gray grey bright-red bright-green bright-yellow
    bright-blue bright-magenta bright-cyan bright-white
    regular strip bold underline underline-double underline-curly
    underline-dotted underline-dashed reverse dim italic strikethrough
]

def "nu-complete fzf color" [context: string] {
    let at = nu-complete fzf split $context ["," ":"]

    if $at.sep == ":" {
        $color_values | each {|v| $"($at.head)($v)" }
    } else {
        [...$color_base_schemes ...$color_names] | each {|v| $"($at.head)($v)" }
    }
}

def "nu-complete fzf keys" [] {
    let letters = "abcdefghijklmnopqrstuvwxyz" | split chars

    [
        ...($letters | each {|c| $"ctrl-($c)" })
        ...($letters | each {|c| $"alt-($c)" })
        ...($letters | each {|c| $"ctrl-alt-($c)" })
        ...(1..12 | each {|n| $"f($n)" })
        ctrl-space ctrl-delete "ctrl-\\" "ctrl-]" "ctrl-^" "ctrl-/"
        enter return space backspace bspace bs tab shift-tab btab esc
        delete del up down left right home end insert page-up pgup page-down pgdn
        alt-up alt-down alt-left alt-right alt-home alt-end
        alt-backspace alt-bspace alt-bs alt-delete alt-page-up alt-page-down
        alt-enter alt-space
        ctrl-up ctrl-down ctrl-left ctrl-right ctrl-home ctrl-end
        ctrl-backspace ctrl-bspace ctrl-bs ctrl-page-up ctrl-page-down
        shift-up shift-down shift-left shift-right shift-home shift-end
        shift-delete shift-page-up shift-page-down
        alt-shift-up alt-shift-down alt-shift-left alt-shift-right
        alt-shift-home alt-shift-end alt-shift-delete
        alt-shift-page-up alt-shift-page-down
        ctrl-alt-up ctrl-alt-down ctrl-alt-left ctrl-alt-right
        ctrl-alt-home ctrl-alt-end ctrl-alt-backspace ctrl-alt-bspace ctrl-alt-bs
        ctrl-alt-delete ctrl-alt-page-up ctrl-alt-page-down
        ctrl-shift-up ctrl-shift-down ctrl-shift-left ctrl-shift-right
        ctrl-shift-home ctrl-shift-end ctrl-shift-delete
        ctrl-shift-page-up ctrl-shift-page-down
        ctrl-alt-shift-up ctrl-alt-shift-down ctrl-alt-shift-left ctrl-alt-shift-right
        ctrl-alt-shift-home ctrl-alt-shift-end ctrl-alt-shift-delete
        ctrl-alt-shift-page-up ctrl-alt-shift-page-down
        left-click right-click double-click shift-left-click shift-right-click
        scroll-up scroll-down shift-scroll-up shift-scroll-down
        preview-scroll-up preview-scroll-down
    ]
}

const fzf_events = [
    start load resize result result-final change focus
    multi one zero backward-eof jump jump-cancel
    click-header click-footer every
]

const transform_actions = [
    transform transform-border-label transform-ghost transform-header
    transform-header-lines transform-header-label transform-input-label
    transform-list-label transform-nth transform-with-nth transform-pointer
    transform-preview-label transform-prompt transform-query transform-search
]

# Why: names are offered bare, without the "(...)" the man page shows on argument-taking actions - an unbalanced "(" in an unquoted nushell token starts a subexpression and breaks the line.
# Not listing toggle+down / toggle+up because: the completer already builds chains after "+", so a literal entry would produce toggle+toggle+down.
def "nu-complete fzf actions" [] {
    [
        abort accept accept-non-empty accept-or-print-query
        backward-char backward-delete-char backward-delete-char/eof
        backward-kill-subword backward-kill-word backward-subword backward-word
        become beginning-of-line bell best bg-cancel cancel
        change-border-label change-ghost change-header change-header-lines
        change-header-label change-input-label change-list-label change-multi
        change-nth change-with-nth change-pointer change-preview
        change-preview-label change-preview-window change-prompt change-query
        clear-screen clear-multi clear-query close
        delete-char delete-char/eof deselect deselect-all
        disable-raw disable-search down down-match down-selected
        enable-raw enable-search end-of-line exclude exclude-multi
        execute execute-silent first forward-char forward-subword forward-word
        half-page-down half-page-up hide-header hide-input hide-preview
        ignore jump kill-line kill-subword kill-word last
        next-history next-selected offset-down offset-up offset-middle
        page-down page-up pos prev-history prev-selected
        preview preview-down preview-up preview-page-down preview-page-up
        preview-half-page-down preview-half-page-up preview-bottom preview-top
        print put rebind refresh-preview reload reload-sync replace-query
        search select select-all show-header show-input show-preview
        toggle toggle-all toggle-in toggle-out toggle-bind toggle-header
        toggle-hscroll toggle-input toggle-multi-line toggle-preview
        toggle-preview-wrap toggle-preview-wrap-word toggle-raw toggle-search
        toggle-sort toggle-track toggle-track-current toggle-wrap toggle-wrap-word
        track-current trigger unbind unix-line-discard unix-word-rubout
        untrack-current up up-match up-selected wait yank
        ...$transform_actions
        ...($transform_actions | each {|a| $"bg-($a)" })
    ]
}

# Why: --bind takes KEY:ACTION pairs joined by commas and chained with "+", so the completer switches on the separator it stopped at - a key or event right after a comma, an action right after ":" or "+".
def "nu-complete fzf bind" [context: string] {
    let at = nu-complete fzf split $context ["," ":" "+"]

    if $at.sep in [":" "+"] {
        nu-complete fzf actions | each {|a| $"($at.head)($a)" }
    } else {
        [...(nu-complete fzf keys) ...$fzf_events] | each {|k| $"($at.head)($k):" }
    }
}

def "nu-complete fzf expect" [context: string] {
    let at = nu-complete fzf split $context [","]

    nu-complete fzf keys | each {|k| $"($at.head)($k)" }
}

# Why: an optional-value flag has to be declared as a switch - nushell rejects a bare `--flag` at the end of a line once the flag is typed, and `ls | fzf -m` must keep working. The *-border family is the deliberate exception: its 16-value list is the one place where completing the value repays that cost.
# Not declaring --help because: nushell answers `fzf --help` with its own signature dump instead of passing the flag through to fzf.
export extern main [
    # SEARCH
    --exact (-e) # Enable exact-match
    --no-extended # Disable extended-search mode (also spelled +x)
    --ignore-case (-i) # Case-insensitive match
    --no-ignore-case # Case-sensitive match (also spelled +i)
    --smart-case # Smart-case match (default)
    --scheme: string@[default path history] # Scoring scheme
    --nth (-n): string # Field index expressions limiting the search scope
    --with-nth: string # Transform the presentation of each line
    --accept-nth: string # Fields to print on accept
    --delimiter (-d): string # Field delimiter regex (default: AWK-style)
    --no-sort # Do not sort the result (also spelled +s)
    --literal # Do not normalize latin script letters
    --tail: int # Maximum number of items to keep in memory
    --disabled # Do not perform search
    --tiebreak: string@"nu-complete fzf tiebreak" # Sort criteria for tied scores

    # INPUT/OUTPUT
    --read0 # Read input delimited by ASCII NUL characters
    --print0 # Print output delimited by ASCII NUL characters
    --ansi # Enable processing of ANSI color codes
    --sync # Synchronous search for multi-staged filtering

    # GLOBAL STYLE
    --style: string@"nu-complete fzf style" # Apply a style preset
    --color: string@"nu-complete fzf color" # Base scheme and/or custom colors
    --no-color # Disable colors
    --no-bold # Do not use bold text

    # DISPLAY MODE
    --height: string # Window height instead of fullscreen, [~][-]HEIGHT[%]
    --min-height: string # Minimum height when --height is a percentage
    --popup # Start fzf in a floating pane (tmux 3.3+ or Zellij 0.44+)
    --tmux # Alias for --popup

    # LAYOUT
    --layout: string@[default reverse reverse-list] # Choose layout
    --margin: string # Screen margin (TRBL | TB,RL | T,RL,B | T,R,B,L)
    --padding: string # Padding inside border
    # Why the *-border flags are switches even though their styles are known: fzf takes the style optionally, and no Nushell signature expresses that. Typing them `string@$border_styles` buys a value menu at the price of `ls | fzf --border` becoming a parse error, and breaking the commonest spelling is worse than losing a menu. The styles still complete where fzf requires them, in --style and --preview-window.
    #
    # Not `--border?: string@$border_styles` because: the `?` does make every spelling parse, but it leaks into the flag menu — completing `fzf --bor` inserts the literal `--border?`, which then fails to parse at all. It also drops the value menu anyway, so it costs the same and adds a trap.
    #
    # The residual cost of the switch, and it is real: `--border=rounded` now fails with "expected bool". `--border rounded` and bare `--border` both work. Same trade for the other optional-value flags here: --multi, --wrap, --gap, --gap-line, --scrollbar, --popup, --tmux, --listen.
    --border # Draw border around the finder
    --border-label: string # Label to print on the border
    --border-label-pos: string # Position of the border label, COL[:bottom]

    # LIST SECTION
    --multi (-m) # Enable multi-select with tab/shift-tab
    --highlight-line # Highlight the whole current line
    --cycle # Enable cyclic scroll
    --wrap # Enable line wrap
    --wrap-sign: string # Indicator for wrapped lines
    --no-multi-line # Disable multi-line display of items when using --read0
    --raw # Enable raw mode (show non-matching items)
    --track # Track the current selection when the result is updated
    --id-nth: string # Item identity fields for cross-reload operations
    --tac # Reverse the order of the input
    --gap # Render empty lines between each item
    --gap-line # Draw horizontal line on each gap
    --freeze-left: int # Number of fields to freeze on the left
    --freeze-right: int # Number of fields to freeze on the right
    --keep-right # Keep the right end of the line visible on overflow
    --scroll-off: int # Screen lines to keep above or below when scrolling
    --no-hscroll # Disable horizontal scroll
    --hscroll-off: int # Columns to keep right of the highlighted substring
    --jump-labels: string # Label characters for jump mode
    --gutter: string # Character used for the gutter column
    --gutter-raw: string # Character used for the gutter column in raw mode
    --pointer: string # Pointer to the current line
    --marker: string # Multi-select marker
    --marker-multi-line: string # Multi-select marker for multi-line entries
    --ellipsis: string # Ellipsis to show when line is truncated
    --tabstop: int # Number of spaces for a tab character
    --scrollbar # Scrollbar character(s)
    --no-scrollbar # Hide scrollbar
    --list-border # Draw border around the list section
    --list-label: string # Label to print on the list border
    --list-label-pos: string # Position of the list label, COL[:bottom]

    # INPUT SECTION
    --no-input # Disable and hide the input section
    --prompt: string # Input prompt
    --info: string@[default right hidden inline inline-right] # Finder info style
    --info-command: string # Command to generate info line
    --separator: string # Horizontal separator string on the info line
    --no-separator # Hide info line separator
    --ghost: string # Ghost text to display when the input is empty
    --filepath-word # Make word-wise movements respect path separators
    --input-border # Draw border around the input section
    --input-label: string # Label to print on the input border
    --input-label-pos: string # Position of the input label, COL[:bottom]

    # PREVIEW WINDOW
    --preview: string # Command to preview highlighted line ({})
    --preview-window: string@"nu-complete fzf preview-window" # Preview window layout
    --preview-border # Short for --preview-window=border-STYLE
    --preview-label: string # Label to print on the preview border
    --preview-label-pos: string # Position of the preview label, COL[:bottom]
    --preview-wrap-sign: string # Indicator for wrapped lines in the preview window

    # HEADER
    --header: string # String to print as header
    --header-lines: int # Treat the first N lines of the input as header
    --header-first # Print header before the prompt line
    --header-border # Draw border around the header section
    --header-lines-border # Separate border for --header-lines
    --header-label: string # Label to print on the header border
    --header-label-pos: string # Position of the header label, COL[:bottom]

    # FOOTER
    --footer: string # String to print as footer
    --footer-border # Draw border around the footer section
    --footer-label: string # Label to print on the footer border
    --footer-label-pos: string # Position of the footer label, COL[:bottom]

    # SCRIPTING
    --query (-q): string # Start the finder with the given query
    --select-1 (-1) # Automatically select the only match
    --exit-0 (-0) # Exit immediately when there is no match
    --filter (-f): string # Print matches for the initial query and exit
    --print-query # Print query as the first line
    --expect: string@"nu-complete fzf expect" # Keys that complete fzf

    # KEY/EVENT BINDING
    --bind: string@"nu-complete fzf bind" # Custom key/event bindings

    # ADVANCED
    --with-shell: string # Shell command and flags to start child processes with
    --listen # Start HTTP server to receive actions (TCP port or .sock path)

    # DIRECTORY TRAVERSAL (only when $FZF_DEFAULT_COMMAND is not set)
    --walker: string@"nu-complete fzf walker" # What the built-in walker lists
    --walker-root: path # Directory to walk (default: .)
    --walker-skip: string # Comma-separated directory names to skip

    # HISTORY
    --history: path # File to store fzf search history
    --history-size: int # Maximum number of entries to keep in the file

    # SHELL INTEGRATION
    --bash # Print script to set up Bash shell integration
    --zsh # Print script to set up Zsh shell integration
    --fish # Print script to set up Fish shell integration
    --nushell # Print script to set up Nushell integration

    # HELP
    --version # Display version information and exit
    --man # Show man page
]
