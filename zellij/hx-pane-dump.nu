#!/usr/bin/env nu

# Dump the focused tiled pane of this tab into a kept, named file with a header saying
# where it came from, then open it in helix.
# Why: a `+ s` tag copied from the dump names this file, so the tag carries the pane's
# source and an agent in the same container can read the whole dump around the quote.
def main [
    --full # dump the full scrollback and open at its end, not just the viewport
] {
    let panes = zellij action list-panes --all --json | from json
    # Not "the first floating pane" as in broot-paste.nu because: with a second floating
    # pane open, that picks the wrong tab.
    let tab = $panes | where id == ($env.ZELLIJ_PANE_ID | into int) and is_plugin == false | first | get tab_id
    let focused = $panes
        | where tab_id == $tab and is_focused == true and is_floating == false and is_plugin == false
    # Why refuse, not take the first: is_focused is true when any attached client focuses the
    # pane, and list-panes does not say which client, so with two clients on this tab the
    # first match can be the other client's pane.
    if ($focused | length) != 1 {
        print $"($focused | length) tiled panes are focused in this tab, one per attached client; cannot tell which one is yours"
        input 'press Enter'
        exit 1
    }
    let target = $focused | first

    let now = date now
    # Why optional: zellij leaves pane_cwd out when it cannot read the pane process's cwd.
    let cwd = $target.pane_cwd?
    let claude = claude-session $target.id
    let nu_id = nu-session $target.id
    let scope = if $full { 'full' } else { 'viewport' }
    let tab_slug = $target.tab_name | str replace --all --regex '[^A-Za-z0-9._-]+' '-'
    let dir = '/tmp/zellij-dumps'
    let file = $dir | path join $"($now | format date '%Y%m%d-%H%M%S')-($tab_slug)-p($target.id).txt"
    mkdir $dir

    let body = zellij action dump-screen --pane-id $target.id ...(if $full { [--full] } else { [] })
    [
        $"# zellij pane ($target.id) · tab ($target.tab_name) · ($now | format date '%F %T') · ($scope)"
        $"# title: ($target.title)"
        ...(if $cwd != null { [$"# cwd: ($cwd)"] } else { [] })
        ...(if $claude != null { [$"# claude session: ($claude)"] } else { [] })
        ...(
            if $nu_id != null {
                [
                    $"# nu session: ($nu_id)"
                    $"#   nu --commands \"open ~/.config/nushell/history.sqlite3 | query db 'select start_timestamp, cwd, exit_status, command_line from history where session_id = ($nu_id) order by id' | to nuon --pretty\""
                ]
            } else { [] }
        )
        ''
        $body
    ]
    | str join "\n"
    | save $file

    hx --config ~/.config/helix/config-no-wrap.toml ...(if $full { ['+99999'] } else { [] }) $file
}

# The sessionId of the Claude Code process running in this zellij pane, or null.
# Why /proc: a claude process inherits its pane's ZELLIJ_* variables, and each one records
# its sessionId in ~/.claude/sessions/<pid>.json. The oldest match is the conversation shown
# in the pane; a younger one is a `claude -p` started from it.
def claude-session [pane_id: int]: nothing -> any {
    let wanted = [$"ZELLIJ_PANE_ID=($pane_id)" $"ZELLIJ_SESSION_NAME=($env.ZELLIJ_SESSION_NAME)"]
    glob ($nu.home-dir | path join .claude sessions *.json)
    | each { open }
    | where {|s|
        # Why try: a process can exit between the glob and this read; it is then no match.
        let vars = try { open --raw $"/proc/($s.pid)/environ" | split row (char nul) } catch { [] }
        $wanted | all { $in in $vars }
    }
    | sort-by startedAt
    | get --optional 0.sessionId
}

# The history session id of the nu shell at the prompt in this zellij pane, or null.
# Why no hook: reedline mints the id as the wall clock in nanoseconds when the REPL starts,
# so it follows the process start time by the config load, about 0.6 s here.
# Why null rather than a near miss: after a sleep of the host the VM clock jumps and the
# start time of an older shell maps hours off, next to another shell's session. A wrong
# id points the agent at someone else's commands; no id costs nothing.
def nu-session [pane_id: int]: nothing -> any {
    # Why: on a macOS host there is no /proc, and the dump must still work.
    if not ('/proc/stat' | path exists) { return null }
    let shells = interactive-shells
    let wanted = [$"ZELLIJ_PANE_ID=($pane_id)" $"ZELLIJ_SESSION_NAME=($env.ZELLIJ_SESSION_NAME)"]
    # Why the youngest: a nu started from another nu in the same pane is the one at the prompt.
    let shell = $shells
        | where {|s| $wanted | all { $in in $s.vars } }
        | sort-by start
        | last
    if $shell == null { return null }

    # Why not $nu.history-path: this script runs without config, where that path is the
    # default plaintext file.
    let id = open ($nu.default-config-dir | path join history.sqlite3)
        | query db 'select min(session_id) as id from history where session_id between ? and ?' --params [$shell.start ($shell.start + 2_000_000_000)]
        | get 0.id
    if $id == null { return null }
    # Why: the id belongs to the shell that started last before it; any other live shell in
    # between, in any pane, makes the match ambiguous.
    if ($shells | any { $in.start > $shell.start and $in.start <= $id }) { return null }
    $id
}

# Live interactive nu processes, with their environment and start time in wall-clock ns.
# Why interactive only: script, MCP and `nu --commands` processes in a pane inherit its
# ZELLIJ_PANE_ID too, but write no history.
def interactive-shells []: nothing -> table {
    let boot_ns = open /proc/stat | lines | where $it starts-with 'btime ' | first
        | split row ' ' | last | into int | $in * 1_000_000_000
    ls /proc | get name | where $it =~ '^/proc/\d+$'
    | each {|p|
        # Why try: a process can exit between the ls and these reads; it is then skipped.
        try {
            let argv = open --raw $"($p)/cmdline" | split row (char nul) | compact --empty
            if ($argv.0 | path basename | str trim --left --char '-') != 'nu' { return null }
            if ($argv | skip 1 | any { $in not-in [--login -l --interactive -i] }) { return null }
            # Field 22 of stat is starttime in clock ticks since boot; the 2nd field may hold
            # spaces, so cut up to its closing paren first. Ticks are 100 Hz in Linux userspace.
            let ticks = open --raw $"($p)/stat" | str replace --regex '^.*\) ' '' | split row ' ' | get 19 | into int
            {
                start: ($boot_ns + $ticks * 10_000_000)
                vars: (open --raw $"($p)/environ" | split row (char nul))
            }
        } catch { null }
    }
    | compact
}
