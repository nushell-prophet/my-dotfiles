#!/usr/bin/env nu

let target = (
    zellij action list-panes -s -j
    | from json
    | where is_focused == true and is_floating == false
    | get id
    | first
)

let config_path = (
    ['conf', 'select']
    | each { $"($env.HOME)/.config/broot/($in).hjson" }
    | str join ';'
)

let selection = ^broot --conf $config_path | str trim

if ($selection | is-not-empty) {
    zellij action write-chars $selection --pane-id $"terminal_($target)"
}
