export def main [] { }

export def copy [] {
    glob '~/.config/nushell/{config,env}.nu'
    | each { cp $in nushell }

    cp ~/.config/nushell/autoload/ nushell -r

    [
        '~/.config/wezterm/'
        '~/.config/helix/'
        '~/.config/zellij/'
        '~/.config/ghostty/'
        '~/.config/broot/'
    ]
    | each {
        path expand
        | if ($in | path exists) { cp $in . -r }
    }
}
