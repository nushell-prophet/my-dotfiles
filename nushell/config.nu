# ═══════════════════════════════════════════════════════════════════════════════
# ▐ NUSHELL CONFIGURATION - BEAUTIFIED & NEWBIE-FRIENDLY
# ═══════════════════════════════════════════════════════════════════════════════
#
# This configuration is designed for easy copy-pasting and understanding.
# Each section is self-contained and clearly documented.
#
# 📍 Quick Navigation:
#   • Basic Configuration
#   • Core Keybindings
#   • Menu Systems
#   • FZF History Picker
#   • Tool Integrations
#
# 🎯 Dependencies Required:
#   - fzf (history search)
#   - broot (file browser)
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ BASIC CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# History Configuration
$env.config.history.file_format = "Sqlite"
$env.config.history.isolation = true
$env.config.history.max_size = 5000000

# Inline history hints (fish-style autosuggestions), scoped to the current folder.
# Set $env.LOCAL_COMPLETIONS = 0 to hint from the whole history; unset or any other value means local.
# Why: direct SQL with LIMIT 1 instead of the `history` builtin — the closure fires per keystroke and the builtin loads the whole table each time. Deliberately bypasses history.isolation (that's about up-arrow, not suggestions).
# Note: str length counts UTF-8 bytes, sqlite substr counts characters — a non-ASCII prefix just yields no hint, never an error.
$env.config.hinter.closure = {|ctx|
    if ($ctx.line | is-empty) { return null }

    # Why: $env.-prefixed lines always hint globally — env manipulation isn't tied to a folder, and the LOCAL_COMPLETIONS toggle itself stays recallable from anywhere.
    let global = ($env.LOCAL_COMPLETIONS? | default 1) == 0 or ($ctx.line | str starts-with '$env.')

    let candidate = open $nu.history-path
        | query db (
            "SELECT command_line FROM history
            WHERE substr(command_line, 1, :len) = :line"
            + (if $global { "" } else { " AND cwd = :cwd" })
            + " ORDER BY id DESC LIMIT 1"
        ) --params (
            {len: ($ctx.line | str length) line: $ctx.line}
            | if $global { } else { insert cwd $ctx.cwd }
        )
        | get --optional 0.command_line

    if $candidate == null or $candidate == $ctx.line {
        null
    } else {
        $candidate | str substring ($ctx.line | str length)..
    }
}

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

# shell_integration.osc8 (bool): Generate clickable links in `ls` output.
# Terminal can launch files in associated applications.
$env.config.shell_integration.osc8 = false

# Why: makes invisible leading/trailing spaces in table cells visible — a classic source of "why doesn't this match" bugs. Table renderer only; bare strings are not touched.
$env.config.color_config.leading_trailing_space_bg = {bg: red}
# Why: exact timestamps over the humanized default ("a day ago") — humanizing throws away the exact value in table work.
$env.config.datetime_format.table = '%y-%m-%d %H:%M:%S'

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ ABBREVIATIONS
# ═══════════════════════════════════════════════════════════════════════════════
# Inline expansion as you type (fires anywhere in the line, not just command position).
# Why: unlike aliases, the expanded command lands in history, so the fzf bindings, the hinter, and history queries see real commands. Replaces the former `alias lg = lazygit` (cozy standard-aliases.nu) for the same reason.
# Keys collision-checked against 7.8k history entries (never typed as command or argument token) and PATH.

$env.config.abbreviations = {
    cs: 'claude --dangerously-skip-permissions'
    cn: 'claude-nu'
    gd: 'git diff'
    gp: 'git pull'
    gs: 'git status'
    gl: 'git log'
    gco: 'git checkout'
    gb: 'git branch'
    grv: 'git remote -v'
    ut: 'use toolkit.nu'
    lg: 'lazygit'
}

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

# ───────────────────────────────────────────────────────────────────────────────
# Navigate history
# Shortcut: Alt+Up/down
# ───────────────────────────────────────────────────────────────────────────────
$env.config.keybindings ++= [
    {
        name: previous_history_item
        modifier: alt
        keycode: Up
        mode: emacs
        event: {send: PreviousHistory}
    }
]

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
            | query db "SELECT cwd FROM history GROUP BY cwd ORDER BY MAX(start_timestamp) DESC"
            | get cwd
            | into string
            | where $it =~ $"\(?i)($buffer_esc)"
            | compact --empty
            | each {
                if $in has (char space) {
                    $'"($in)"' # enclose entry into quotes
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

# Not using nushell menu because `scope variables` inside a menu source closure
# only sees closure-local scope since ~0.101 (nushell/nushell#14071).
# Using `executehostcommand` + fzf instead — runs in REPL scope, sees all variables.
$env.config.keybindings ++= [
    {
        name: vars_menu
        modifier: alt
        keycode: char_o
        mode: [emacs]
        event: {
            send: executehostcommand
            cmd: (vars-menu-source)
        }
    }
]

def vars-menu-source [] {
    let closure = {
        let selected = scope variables
            | where name not-in ($env.ignore-env-vars? | default [])
            | sort-by var_id -r
            | each { $"($in.name)\t($in.type)" }
            | str join (char nul)
            | ^fzf --read0 --no-sort --layout=reverse --height=40% --delimiter="\t"
            | decode utf-8
            | str trim
            | split row "\t"
            | first

        if ($selected | is-not-empty) {
            commandline edit --insert $selected
        }
    }

    view source $closure | lines | skip | drop | to text
}

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
# ▐ FZF HISTORY PICKER
# ═══════════════════════════════════════════════════════════════════════════════
# One binding for all history recall.
# Shortcut: Ctrl+F
# Dependencies: fzf 0.73+
#
# Why one binding: the former Ctrl+F (insert, empty query) / Alt+F (prefix
# search, replace) pair shared 90% of their logic but drifted apart — the shared
# preview only worked for Ctrl+F's entry format, Alt+F's dedup relied on
# DISTINCT over an ordered subquery (SQLite doesn't guarantee that order), and
# one leg of the indent-compression was dead code. Now the accept key decides
# the outcome instead of the opening key:
#   enter      replace the commandline with the selection
#   alt-enter  insert the selection at the cursor
# Multi-select (tab) joins entries with `;` + newline.
#
# The current commandline (if any) becomes the initial query, anchored as ONE
# literal prefix term — spaces are backslash-escaped so fzf doesn't split terms
# (and `|` can't become an OR-operator). Ctrl+U in fzf clears it.
#
# In-picker keys (see --header):
#   alt-c            toggle "current directory only" (prompt shows `cwd> `) —
#                    picker-side counterpart of the LOCAL_COMPLETIONS hinter toggle
#   ctrl-f / ctrl-r  toggle relevance sort (list starts in recency order)
#   alt-r            toggle raw display
#
# Preview shows when/where the command ran (timestamp, duration, exit status,
# cwd — fetched from the history db by id) above the highlighted command.

$env.config.keybindings ++= [
    {
        name: fzf_history
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: {
            send: executehostcommand
            cmd: (fzf-history-source)
        }
    }
]

def fzf-history-source [] {
    let closure = {
        # Why helper scripts (scripts/fzf-hist-*.nu, deployed next to config.nu):
        # fzf's reload/preview run nu via `sh -c`; inlining nu code there means
        # three quoting layers. Real files beat generated temp files: no
        # predictable world-writable /tmp path re-executed by fzf, and the
        # scripts get git history and ide-check coverage.
        # Why the db path is an argument: `nu -n` resolves $nu.history-path to
        # the plaintext default, not the sqlite file this config sets.
        let scripts_dir = $nu.config-path | path dirname | path join 'scripts'
        let src_script = $scripts_dir | path join 'fzf-hist-source.nu'
        let preview_script = $scripts_dir | path join 'fzf-hist-preview.nu'
        let db = $nu.history-path

        let query = commandline
            | str replace --all ' ' '\ '
            | if ($in | is-empty) { '' } else { $'^($in)' }

        let reload = $"reload:nu -n --no-std-lib \"($src_script)\" \"($db)\""
        let cwd_toggle = ($"[ \"$FZF_PROMPT\" = \"cwd> \" ]"
            + $" && echo 'change-prompt\(> )+($reload)'"
            + $" || echo 'change-prompt\(cwd> )+($reload) --cwd'")

        let selection = '' | ^fzf ...[
            '--read0'
            '--print0'
            '--multi'
            '--cycle'
            '--layout=reverse'
            '--height=70%'
            '--wrap'
            "--wrap-sign=\t↳ "
            '--no-sort' # start in recency order; ctrl-f/ctrl-r switch to relevance
            '--tiebreak=begin,length,chunk'
            "--delimiter=\t"
            '--nth=2..' # match on the command, not the id column
            '--with-shell=sh -c'
            '--prompt=> '
            $'--query=($query)'
            '--expect=alt-enter'
            '--header=enter replace · alt-enter insert · alt-c cwd · ctrl-f sort · alt-r raw'
            '--header-first'
            '--bind=ctrl-f:toggle-sort'
            '--bind=ctrl-r:toggle-sort'
            '--bind=alt-r:toggle-raw'
            $'--bind=start:($reload)'
            $'--bind=alt-c:transform:($cwd_toggle)'
            '--preview-window=bottom:30%:wrap'
            $'--preview=nu -n --no-std-lib "($preview_script)" "($db)" {1} {2..}'
        ] | complete

        match $selection.exit_code {
            0 => {
                # --print0 + --expect output: <accept key> NUL <entry> NUL <entry> NUL
                let out = $selection.stdout | split row (char nul)
                let picked = $out
                    | skip 1
                    | compact --empty
                    | str replace --regex '^\d+\t' ''
                    | str join $";(char nl)"

                if ($out | first) == 'alt-enter' {
                    commandline edit --insert $picked
                } else {
                    commandline edit --replace $picked
                    commandline set-cursor --end
                }
            }
            1 | 130 => { } # no match / cancelled: leave the commandline untouched
            _ => { error make {msg: $selection.stderr} }
        }
    }

    view source $closure | lines | skip | drop | to text
}

# ═══════════════════════════════════════════════════════════════════════════════
# ▐ TOOL INTEGRATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Copy Command to Clipboard
# Shortcut: Ctrl+Alt+C
# Usage: Copies current command line to clipboard and adds confirmation
# pbcopy is native on macOS; in cozy it's an OSC52 shim (cozy/docker-files/pbcopy),
# the same clipboard path zellij/helix/lazygit use — portable, not Mac-only
# ───────────────────────────────────────────────────────────────────────────────

$env.config.keybindings ++= [
    {
        name: copy_command
        modifier: control_alt
        keycode: char_c
        mode: [emacs]
        event: {
            send: executehostcommand
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
# ~/.config/nushell/autoload/zzz_ignore_vars.nu
$env.ignore-env-vars = (scope variables | get name)
