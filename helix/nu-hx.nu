# Helpers behind the Helix `+` keybindings (config.toml [keys.normal."+"]).
# Loaded by hx-nu via nu-hx-config.nu, so `nu-hx <cmd>` is available in every
# Helix shell call, including nested `hx-nu -c` evaluations.
#
# Why a module: the bindings used to inline this code in config.toml, pasting the
# selection into the command text through r###########'%{selection}'########### raw
# strings — which breaks on unlucky content (e.g. a stray '#). Here the selection
# arrives on STDIN instead (Helix pipes it for :pipe/:pipe-to — but NOT for
# :append-output/:insert-output, so bindings must use the pipe family), and needs
# no escaping. Only %{buffer_name} and line numbers are still substituted. As a
# .nu file the logic also gets highlighting, `nu --ide-check`, and topiary.
#
# Named nu-hx (not hx) because: `hx annotate` reads as a call to the editor binary.

const HX_BLOCK = path self | path dirname | path join hx-block

# Evaluate the selection and return it with its output appended as `# => ` comment
# lines (the `+ a` / `+ A` bindings). For :pipe, which replaces the selection, so
# the selection itself is echoed back first.
export def annotate [
    --abbreviate # keep the first 7 output lines and note how many were dropped
]: string -> string {
    let sel = $in
    let out = hx-nu -c $sel o+e>| lines
    let len = $out | length

    $out
    | if $abbreviate and $len > 7 {
        first 7 | append $"... and ($len - 7) more lines"
    } else { }
    | each { $"# => ($in)" }
    # selection ends mid-line -> start the comments on a fresh line
    | if ($sel ends-with "\n") { } else { prepend '' }
    | to text
    | $sel + $in
}

# Strip the `# => ` lines produced by `annotate` (the `+ C` binding).
export def clear-annotations []: string -> string {
    lines | where $it !~ '^# =>' | to text
}

# Evaluate the selection and flatten the result to one NUON line (the `+ f` binding).
# `to nuon` is appended INSIDE the eval: applied outside it would serialize the
# rendered table text, not the data. On its own line so a trailing comment in the
# selection can't swallow it; the selection is right-trimmed so no blank line lands
# between the pipeline and the continuation.
export def flatten []: string -> string {
    let cmd = $in | str trim --right | $in + "\n| to nuon"
    hx-nu -c $cmd o+e>| str trim --right
}

# Evaluate the selection and write the result as a rectangle on the line(s) below
# it, via hx-block (the `+ b` binding). Edits the file on disk, so the binding
# wraps it in :write / :reload. `run` (0.114) executes hx-block in-process:
# pipeline input reaches its main directly, no extra nu spawn per press.
export def block-below [
    file: string # buffer path (Helix %{buffer_name})
    line: int # anchor line (Helix %{selection_line_end})
]: string -> nothing {
    hx-nu -c $in | run $HX_BLOCK --below $file $line
}

# Re-align a selected markdown table so its columns line up (the `+ p` binding).
# Only the padding inside the cells changes; cell text is left as written.
# Not pandoc because: it needs an external binary and rewrites the WHOLE selection
# (escapes, list markers, wrapping), not just the table.
export def align-table []: string -> string {
    let src = $in | lines
    let rows = $src | each { str trim }

    let stray = $rows | enumerate | where not ($it.item starts-with '|')
    if ($stray | is-not-empty) {
        error make {msg: $"line ($stray.0.index + 1) is not a table row: ($stray.0.item)"}
    }
    if ($rows | length) < 2 {
        error make {msg: 'a markdown table needs a header row and a separator row'}
    }

    # a table indented under a list item keeps that indent
    let indent = $src | first | parse --regex '^(?<i>\s*)' | get 0.i
    let cells = $rows | each { split-cells }
    let seps = $cells | get 1
    if not ($seps | all { $in =~ '^:?-+:?$' }) {
        error make {msg: $"line 2 is not a separator row: ($rows | get 1)"}
    }

    # a ragged row is padded out, not rejected: markdown renderers accept it too
    let n = $cells | each { length } | math max
    let table = $cells | each {|row| $row | append (($row | length)..<$n | each { '' }) }
    let marks = 0..<$n | each {|i|
        let s = $seps | get --optional $i | default '-'
        {left: ($s starts-with ':'), right: ($s ends-with ':')}
    }
    # `str length` counts graphemes, not display columns, so a CJK or emoji cell
    # still lands short — every ASCII table lines up
    let widths = 0..<$n | each {|i|
        $table | reject 1 | each {|row| $row | get $i | str length --grapheme-clusters } | append 3 | math max
    }

    $table
    | enumerate
    | each {|row|
        $marks
        | zip $widths
        | enumerate
        | each {|col|
            let mark = $col.item.0
            let width = $col.item.1
            if $row.index == 1 {
                '' | fill --character '-' --width $width
                | if $mark.left { ':' + ($in | str substring 1..) } else { }
                | if $mark.right { ($in | str substring ..<(-1)) + ':' } else { }
            } else {
                let align = match [$mark.left $mark.right] {
                    [false true] => 'r'
                    [true true] => 'c'
                    _ => 'l'
                }
                $row.item | get $col.index | fill --width $width --alignment $align
            }
        }
        | str join ' | '
        | $"($indent)| ($in) |"
    }
    | to text
}

# Split one markdown table row into trimmed cells. The lookbehind keeps an escaped
# `\|` inside a cell from being read as a column break.
def split-cells []: string -> list<string> {
    str replace --regex '^\|' ''
    | str replace --regex '(?<!\\)\|$' ''
    | split row --regex '(?<!\\)\|'
    | each { str trim }
}

# Copy the selection to the clipboard as an XML <selected-text> tag with file+line
# coordinates (the `+ s` / `+ S` bindings). The path is REPO-RELATIVE (git
# show-prefix + basename); outside a git repo it falls back to the ABSOLUTE path,
# not a bare basename. --absolute skips git entirely.
export def copy-tag [
    file: string # buffer path (Helix %{buffer_name})
    start: int # first selected line (Helix %{selection_line_start})
    end: int # last selected line (Helix %{selection_line_end})
    --absolute # use the absolute path even inside a git repo
]: string -> nothing {
    let sel = $in
    # `path expand` + `git -C` so the lookup hits the file's real dir, not Helix's cwd
    let abs = $file | path expand
    let path = if $absolute { $abs } else {
        let res = ^git -C ($abs | path dirname) rev-parse --show-prefix | complete
        if $res.exit_code == 0 { $"($res.stdout | str trim)($abs | path basename)" } else { $abs }
    }
    $'<selected-text file="($path)" lines="($start)-($end)">($sel)</selected-text>' | pbcopy
}
