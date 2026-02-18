# ═══════════════════════════════════════════════════════════════════════════════
# ▐ NUSHELL CONFIGURATION - BEAUTIFIED & NEWBIE-FRIENDLY
# ═══════════════════════════════════════════════════════════════════════════════
#
# This configuration is designed for easy copy-pasting and understanding.
# Each section is self-contained and clearly documented.
#
# 📍 Quick Navigation:
#   • Basic Configuration
#   • Keyboard Shortcuts
#   • Core Keybindings
#   • Menu Systems
#   • FZF Integration
#   • Tool Integrations
#   • External Dependencies
#
# 🎯 Dependencies Required:
#   - carapace (completions)
#   - fzf (history search)
#   - broot (file browser)
#   - zellij (terminal multiplexer)
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ BASIC CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# History Configuration
$env.config.history.file_format = "Sqlite"
$env.config.history.isolation = true
$env.config.history.max_size = 5000000

# Terminal & Display Settings
$env.config.use_kitty_protocol = true
$env.config.table.header_on_separator = true
$env.config.table.show_empty = false
$env.config.table.trim = {
    methodology: "truncating"
    truncating_suffix: "…"
}
$env.config.footer_mode = "Always"
$env.config.highlight_resolved_externals = true
$env.config.render_right_prompt_on_last_line = true
$env.config.show_banner = false

# Completions Configuration
$env.config.completions.algorithm = "Fuzzy"
$env.config.completions.partial = false
$env.config.completions.quick = false
$env.config.completions.use_ls_colors = false
$env.config.completions.case_sensitive = false

# Cursor Shape Configuration
$env.config.cursor_shape.emacs = "Line"
$env.config.cursor_shape.vi_insert = "Block"
$env.config.cursor_shape.vi_normal = "Underscore"

# Safety Settings
$env.config.rm.always_trash = false

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ CORE KEYBINDINGS
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Smart End-of-Line Navigation with History Hints
# Shortcut: Ctrl+E
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: move_to_line_end_or_take_history_hint
        modifier: control
        keycode: char_e
        mode: [emacs vi_normal vi_insert]
        event: {
            until: [
                {send: historyhintcomplete}
                # {edit: movetolineend}
                {edit: movetoend}
            ]
        }
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Enhanced Cut to End
# Shortcut: Ctrl+K
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: cut_line_to_end
        modifier: control
        keycode: char_k
        mode: emacs
        #       event: { edit: cuttolineend } # this is the default nushell shortcut
        event: {edit: cuttoend}
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Swap Adjacent Characters
# Shortcut: Ctrl+Alt+T
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: swap_graphemes
        #       modifier: control # this is the default nushell shortcut
        modifier: control_alt
        keycode: char_t
        mode: emacs
        event: {edit: swapgraphemes}
    }
]

$env.config.keybindings ++= [
    {
        name: previous_history_item
        modifier: alt
        keycode: Up
        mode: emacs
        event: {send: PreviousHistory}
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Navigate history
# Shortcut: Alt+Up/down
# ───────────────────────────────────────────────────────────────────────────────
$env.config.keybindings ++= [
    {
        name: next_history_item
        modifier: alt
        keycode: Down
        mode: emacs
        event: {send: NextHistory}
    }
]

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ MENU SYSTEMS
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Working Directories Menu - Quick navigation to recent directories
# Shortcut: Alt+Shift+R
# Usage: Browse directories from command history, Enter to cd
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: working_dirs_cd_menu
        modifier: alt_shift
        keycode: char_r
        mode: emacs
        event: {send: menu name: working_dirs_cd_menu}
    }
]

$env.config.menus ++= [
    {
        # List all unique successful commands
        name: working_dirs_cd_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: list
            page_size: 23
        }
        style: {
            text: green
            selected_text: green_reverse
        }
        source: {|buffer position|

             let $buffer_esc = $buffer | str replace -ar '(_|-)' '_|-'

            open $nu.history-path
            | query db "SELECT DISTINCT(cwd) FROM history ORDER BY id DESC"
            | get cwd
            | into string
            | where $it =~ $"\(?i)($buffer_esc)"
            | compact --empty
            | each {
                if ($in has ' ') {
                    $'"($in)"'
                } else { }
                | {value: $in}
            }
        }
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Variables Menu - Browse and insert shell variables
# Shortcut: Alt+O
# Usage: Type part of variable name to filter, Enter to insert
#
# Note: $env.ignore-env-vars is initialized at the end of this configuration file
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: vars_menu
        modifier: alt
        keycode: char_o
        mode: [emacs]
        event: {send: menu name: vars_menu}
    }
]

$env.config.menus ++= [
    {
        name: vars_menu
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: {|buffer position|
            scope variables
            # Filter out variables captured at config initialization (see end of file)
            | where name not-in ($env.ignore-env-vars? | default [])
            | sort-by var_id -r
            | where name =~ $buffer
            | each {|it| {value: $it.name description: $it.type} }
        }
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Convert Command Line to Raw String Literal
# Shortcut: Ctrl+V
# Usage: Wraps current command in raw string format for easy copying
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: prompt_to_raw_string
        modifier: control
        keycode: char_v
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: (prompt_to_raw_source)
        }
    }
]

def prompt_to_raw_source [] {
    let closure = {
        let input = commandline
        let hashes = $input | parse -r '(#+)' | get capture0 | sort -r | get 0? | default '' # find longest hash

        $" r#($hashes)'($input)'#($hashes)" | commandline edit -r $in
    }

    view source $closure | lines | skip | drop | to text
}

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ FZF INTEGRATION SUITE
# ═══════════════════════════════════════════════════════════════════════════════
# Advanced history search and navigation using fzf
# Dependencies: fzf (brew install fzf)

# Base FZF parameters for consistent history function behavior
$env.FZF_HISTORY_BASE = [
    '--cycle'
    '--read0'
    '--print0'
    '--layout=reverse'
    '--multi'
    '--height=70%'
    '--wrap'
    "--wrap-sign=\t↳ "
    '--tiebreak=begin,length,chunk'
    '--bind=load:toggle-sort' # Sort with initially provided order
    '--bind=alt-r:toggle-raw'
    '--with-shell=sh -c'
    '--preview-window=bottom:30%:wrap'
    '--preview=echo {2} | nu -n --no-std-lib --stdin -c "nu-highlight" '
]

# ───────────────────────────────────────────────────────────────────────────────
# FZF Multi-Select History Insertion
# Shortcut: Ctrl+F
# Usage: Search and select multiple history entries to insert
# Features: Syntax highlighting, sorting toggle, multi-select
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: fzf_history_entries
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: (fzf-hist-all-reverse-append)
        }
    }
]

def 'fzf-hist-all-reverse-append' [] {
    let closure = {
        let index_sep = "\u{200C}\t"
        let entry_sep = "\u{200B}"

        open $nu.history-path
        | query db '
            WITH ordered_history AS (
                SELECT
                    id,
                    command_line,
                    ROW_NUMBER() OVER (PARTITION BY command_line ORDER BY id DESC) AS row_num
                FROM history
            )
            SELECT
                id,
                command_line
            FROM ordered_history
            WHERE row_num = 1
            ORDER BY id DESC;
        '
        | each { $"($in.id)($index_sep)($in.command_line)" }
        | str join (char nul)
        | ^fzf ...(
            $env.FZF_HISTORY_BASE ++ [
                '--bind=ctrl-r:toggle-sort'
                '--bind=ctrl-f:toggle-sort'
                $'--delimiter=($index_sep)'
                '-n2..'
            ]
        )
        | decode utf-8
        | str trim --char (char nl)
        | str replace -ar $'(char lp)^|(char nul)(char rp)\d+?($index_sep)' '$1'
        | str trim --char (char nul)
        | str replace -ar (char nul) $';(char nl)'
        | str replace -r $';(char nl)$' ''
        | str replace -a $entry_sep '    '
        | str trim
        | commandline edit --insert $in
    }

    view source $closure | lines | skip | drop | to text
}

# ───────────────────────────────────────────────────────────────────────────────
# FZF Prefix History Search and Replace
# Shortcut: Alt+F
# Usage: Search history with current line as prefix, replace entire line
# Features: Prefix filtering, fuzzy search, line replacement
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: fzf_history
        modifier: alt
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: (fzf-hist-current-commandline-prefix-replace)
        }
    }
]

# find the '^' prefixed current commandline in whole history; replace current commandline
def 'fzf-hist-current-commandline-prefix-replace' [] {
    let closure = {
        open $nu.history-path
        | query db '
            WITH ordered_history AS (
                SELECT command_line
                FROM history
                ORDER BY id DESC
            )
            SELECT DISTINCT command_line
            FROM ordered_history;
        '
        | get command_line
        | each { str replace -a '    ' "\u{200B}" }
        | str join (char nul)
        | ^fzf ...(
            $env.FZF_HISTORY_BASE ++ [
                $'--query=^(commandline | str replace -a "| " "")'
                '--header=ctrl-r to disable sort'
                '--header-first'
                '--bind=ctrl-r:toggle-sort'
                '--bind=alt-f:toggle-sort'
            ]
        )
        | decode utf-8
        | str trim --char (char nl)
        | str replace -ar (char nul) $';(char nl)'
        | str replace -r $';(char nl)$' ''
        | str replace -a "\u{200B}" '    '
        | str trim
        | if ($in | is-empty) { } else {
            commandline edit --replace $in;
            commandline set-cursor -e
        }
    }

    view source $closure | lines | skip | drop | to text
}

# ───────────────────────────────────────────────────────────────────────────────
# FZF Context-Aware Session Search
# Shortcut: Alt+Ctrl+F
# Usage: Search sessions that contain similar commands to current input
# Features: Context awareness, session correlation, command appending
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: fzf_history_sessions
        modifier: alt_control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: (fzf-hist-with-sessions-that-include-current-entry)
        }
    }
]

def 'fzf-hist-with-sessions-that-include-current-entry' [] {
    let closure = {
        open $nu.history-path
        | query db -p [
            (commandline | split row -r $';(char nl)?' | str trim | compact --empty | to json)
        ] "
            WITH json_values AS (
                SELECT value
                FROM json_each(?)
            )
            SELECT DISTINCT command_line
            FROM history AS session_history
            WHERE EXISTS (
                SELECT 1
                FROM json_values
                WHERE session_history.command_line LIKE '%' || json_values.value || '%'
            )
        "
        | get command_line
        | each { str replace -a '    ' "\u{200B}" }
        | str join (char nul)
        | ^fzf ...(
            $env.FZF_HISTORY_BASE ++ [
                '--no-sort'
            ]
        )
        | decode utf-8
        | str trim --char (char nl)
        | str replace -ar (char nul) $';(char nl)'
        | str replace -r $';(char nl)$' ''
        | str replace -a "\u{200B}" '    '
        | str trim
        | commandline edit -a $in
        | commandline set-cursor -e
    }

    view source $closure | lines | skip | drop | to text
}

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ TOOL INTEGRATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Copy Command to Clipboard (macOS)
# Shortcut: Ctrl+Alt+C
# Usage: Copies current command line to clipboard and adds confirmation
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: copy_command
        modifier: control_alt
        keycode: char_c
        mode: [emacs]
        event: {
            send: executehostcommand
            # macos version command below
            cmd: "commandline | pbcopy; commandline edit --append ' # copied'"
        }
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Broot File Browser Integration
# Shortcut: Ctrl+T
# Dependencies: broot (cargo install broot)
# Usage: Opens broot file browser, inserts selected path at cursor
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: broot_path_completion
        modifier: control
        keycode: char_t
        mode: [emacs]
        event: [
            {
                send: ExecuteHostCommand
                cmd: (broot-source)
            }
        ]
    }
]

def broot-source [] {
    let broot_closure = {
        let cl = commandline
        let pos = commandline get-cursor

        let element = ast --flatten $cl
        | flatten
        | where start <= $pos and end >= $pos
        | get content.0 -o
        | default ''

        let path_exp = $element
        | str trim -c '"'
        | str trim -c "'"
        | str trim -c '`'
        | if $in =~ '^~' { path expand } else { }
        | if ($in | path exists) { } else { '.' }

        let config_path = $env.XDG_CONFIG_HOME?
        | default '~/.config'
        | path join broot '{conf,select}.hjson'
        | str expand
        | path expand
        | str join ';'

        let broot_path = ^broot $path_exp --conf $config_path
        | path expand

        let rel_path = try {
            $broot_path
            | path relative-to (pwd)
        } catch { $broot_path }
        | if ' ' in $in { $"`($in)`" } else { }

        if $path_exp == '.' {
            commandline edit --insert $rel_path
        } else {
            $cl | str replace $element $rel_path | commandline edit -r $in
        }
    }

    view source $broot_closure | lines | skip | drop | to text
}

# ───────────────────────────────────────────────────────────────────────────────
# Exit Shell with Super+D (macOS Cmd+D)
# Shortcut: Super+D (Cmd+D)
# Usage: Quick exit from shell
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: exit_on_cmdD
        modifier: super
        keycode: char_d
        mode: [emacs]
        event: {send: CtrlD}
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# String Interpolation Template
# Shortcut: Alt+Shift+'
# Usage: Inserts $"" template with cursor positioned inside quotes
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: paste_interpolation
        modifier: alt_shift
        keycode: "char_'"
        mode: [emacs]
        event: {
            send: executehostcommand
            cmd: r#'commandline edit --insert '$""'; commandline set-cursor ((commandline get-cursor) - 1)'#
        }
    }
]

# ───────────────────────────────────────────────────────────────────────────────
# Smart Pipe Completions Menu - Intelligent command continuation
# Shortcut: Shift+Alt+S
# Usage: Suggests completions based on command context and history
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: pipe_completions_menu
        modifier: shift_alt
        keycode: char_s
        mode: emacs
        event: {send: menu name: pipe_completions_menu}
    }
]

$env.config.menus ++= [
    {
        # session menu
        name: pipe_completions_menu
        only_buffer_difference: false # Search is done on the text written after activating the menu
        marker: "# "
        type: {layout: list page_size: 25}
        style: {text: green selected_text: green_reverse description_text: yellow}
        source: {|buffer position|
            let last_segment = $buffer | split row -r '(\s\|\s)|\(|;|(\{\|\w\| )' | last
            let last_segment_length = $last_segment | str length

            let regex = '\.^$*+?{}()[]|/' | split chars | each { $'\($in)' } | str join '|' | $"\(($in))"

            let last_segment_escaped = $last_segment | str replace --all --regex $regex '\$1'

            history
            | get command
            | uniq
            | where $it =~ $last_segment_escaped
            | str replace -a (char nl) ' ' # might cause troubles?
            | str replace -r $'.*($last_segment_escaped)' $last_segment
            | reverse
            | uniq
            | each {|it| {value: $it span: {start: ($position - $last_segment_length) end: ($position)}} }
        }
    }
]

# Custom module imports are handled in the autoload/ directory

# Initialize list of environment variables to exclude from the Alt+O variables menu
# This captures the baseline state before loading additional modules
# 
# mind that there is another invocation in
# /Users/user/.config/nushell/autoload/zzz_ignore_vars.nu
$env.ignore-env-vars = (scope variables | get name)
source $"($nu.home-dir)/.cargo/env.nu"
