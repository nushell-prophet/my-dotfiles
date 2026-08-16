# Load the external-CLI completions that ship next to this file, in
# ~/.config/nushell/completions/.
#
# Why a loader instead of dropping the files straight into this autoload dir:
# autoload `source`s a file, and every completion file is built on
# `export extern main` (the "file name IS the command name" convention). That
# name only resolves through `use` — `source completions/fd.nu` registers a
# command literally called `main`, not `fd`. So each file has to be `use`d, by
# name, and a hand-kept list is the only way: `use` takes no glob.
#
# Nushell also does not recurse into autoload subdirectories, so the completion
# files cannot live one level down from here and be picked up on their own.
#
# When adding a file here: never declare --help or -h in it. Nushell intercepts
# both for anything carrying a signature, an extern included, and prints the
# signature instead of running the binary — so a declared --help silently
# replaces the tool's own help with ours. Leave it out and nushell passes it
# through. Every file in this directory shipped with that bug once.

use ~/.config/nushell/completions/bat.nu *
use ~/.config/nushell/completions/chafa.nu *
use ~/.config/nushell/completions/delta.nu *
use ~/.config/nushell/completions/fd.nu *
use ~/.config/nushell/completions/fzf.nu *
use ~/.config/nushell/completions/hx.nu *
use ~/.config/nushell/completions/lazygit.nu *
use ~/.config/nushell/completions/rg.nu *
use ~/.config/nushell/completions/sandbox-exec.nu *
use ~/.config/nushell/completions/vd.nu *
use ~/.config/nushell/completions/zellij.nu *
