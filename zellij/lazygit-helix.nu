#!/usr/bin/env nu

let target_pane = (
    zellij action list-panes --state --json
    | from json
    | where is_focused == true and is_floating == false
    | first
)

let pane = $"terminal_($target_pane.id)"
let is_helix = ($target_pane.pane_command? | default "" | str contains "hx")

if $is_helix {
    zellij action send-keys Esc --pane-id $pane
}

lazygit

if $is_helix {
    zellij action write-chars ":reload-all\u{0d}" --pane-id $pane
}
