#!/usr/bin/env nu

# Generate Windows-compatible zellij config from the macOS config.
#
# On macOS, global shortcuts use Super (Cmd). On Windows, Win+key is reserved
# by the OS, so we remap:
#   Super Shift → Alt Shift
#   Super Alt   → Ctrl Alt
#   Super       → Alt

def main [
    --source: path = "config.kdl"  # macOS config to transform
    --output: path = "config-windows.kdl"  # output path
] {
    let content = open $source --raw

    # Replace compound modifiers first (longest match), then bare Super.
    # The quote prefix ensures we only match inside bind strings.
    let result = $content
        | str replace --all '"Super Shift ' '"Alt Shift '
        | str replace --all '"Super Alt ' '"Ctrl Alt '
        | str replace --all '"Super ' '"Alt '

    $result | save --force $output
    print $"Generated ($output) from ($source)"
}
