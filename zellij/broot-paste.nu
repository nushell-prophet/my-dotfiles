#!/usr/bin/env nu

let panes = zellij action list-panes --state --json | from json
let me = $panes | where is_floating == true | first
let target = $panes
    | where is_focused == true and is_floating == false and tab_id == $me.tab_id
    | get id
    | first

let config_path = (
    ['conf', 'select']
    | each { $"($env.HOME)/.config/broot/($in).hjson" }
    | str join ';'
)

let selection = ^broot --conf $config_path | str trim

if ($selection | is-not-empty) {
    zellij action write-chars $selection --pane-id $"terminal_($target)"
}
