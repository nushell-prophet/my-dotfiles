#!/usr/bin/env nu
def main [...rest: string] {
    exec hx --config ~/.config/helix/config-no-wrap.toml ...$rest
}
