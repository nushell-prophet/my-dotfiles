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
