#!/usr/bin/env nu
# Re-quote the response Claude Code pastes above the reply marker in its $EDITOR file:
# git-style `# ` comments in, markdown blockquotes out.
#
# ctrl+g ("Show last response in external editor") writes $TMPDIR/claude-prompt-<uuid>.md:
# a banner line, the last response with every line prefixed `# ` (a bare `#` for empty
# lines), then the marker line. The file is .md, so those prefixes turn the whole
# response into headings — the one convention markdown does NOT share with git. Here
# they become `> `, which is how markdown marks quoted text.
#
# Safe by construction: on save Claude Code keeps only what follows the marker
# (2.1.223 reads it back with `content.indexOf(marker)` + slice), so the quoted block
# is discarded whatever it looks like. Nothing here can change what the prompt sends.
# The marker line and everything below it are left byte-for-byte.
#
# Called by hx-quote, never by helix itself.

# Match the words, not the whole line: the trailing ─ run is a fixed width today, and
# surviving a change to it costs nothing.
const MARKER = '# ─── Write your reply below this line'

def main [file: path] {
    # `let` first: splitting the byte stream straight from `open` drops the empty element a
    # trailing newline leaves behind, and with it the file's final newline
    let text = open --raw $file | into string
    let lines = $text | split row "\n"
    # Find the marker as a LINE, not as a substring: a copy of it inside the response always
    # carries Claude Code's own `# ` in front, so `# # ─── Write…` cannot be mistaken for it.
    let at = $lines | enumerate | where { $in.item | str starts-with $MARKER } | get --optional 0.index
    # no marker -> a plain prompt file (ctrl+g with nothing quoted), or not ours at all
    if $at == null or $at == 0 { return }

    # That copy is what Claude Code's reader hits first (indexOf), so today it cuts above the
    # real marker and pastes the leftover quoted lines into the prompt. Turning its `#` into
    # `>` too is enough for indexOf to miss it. Only the discarded block is touched, so this
    # repairs the cut without changing a byte of what gets sent.
    let quoted_marker = $MARKER | str replace '#' '>'

    # only the leading `#` changes, so the space Claude Code put after it is kept: `# text` -> `> text`.
    # A line that is just `#` was an empty line in the response; a lone `>` marks nothing, so that
    # one is emptied first and the `>` rule then finds nothing to do.
    $lines
    | take $at
    | skip 1
    | each {
        str replace --regex '^#\s*$' ''
        | str replace --regex '^#' '>'
        | str replace --all $MARKER $quoted_marker
    }
    # the banner stays a heading: it is the one line where `# ` means what markdown thinks
    | prepend ($lines | first)
    | append ($lines | skip $at)
    | str join "\n"
    | save --force $file
}
