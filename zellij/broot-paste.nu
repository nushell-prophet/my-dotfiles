#!/usr/bin/env nu

let panes = zellij action list-panes --state --json | from json
let me = $panes | where is_floating == true | first
let target = $panes
    | where is_focused == true and is_floating == false and tab_id == $me.tab_id
    | get id
    | first

let config_path = (
    ['conf' 'select']
    | each { $"($env.HOME)/.config/broot/($in).hjson" }
    | str join ';'
)

let pwd = pwd

let selection = ^broot --conf $config_path | str trim

if ($selection | is-not-empty) {
    # Why: clipboard always gets the absolute path — usable from any cwd, unlike the
    # pasted form; pbcopy is native on macOS and an OSC 52 shim in cozy
    $selection | pbcopy
    let to_paste = $selection | if $in starts-with $pwd { path relative-to $pwd } else { }
    zellij action write-chars $to_paste --pane-id $"terminal_($target)"
}
