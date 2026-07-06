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
export def flatten []: string -> string {
    hx-nu -c $in o+e>| to nuon
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
