#!/usr/bin/env nu
def main [...rest: string] {
    hx --config ~/.config/helix/config-no-wrap.toml ...$rest
}
