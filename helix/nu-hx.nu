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
# wraps it in :update / :reload. `run` (0.114) executes hx-block in-process:
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

# Copy the selection as a <selected-text> tag addressed by a change-id link (the `+ t` binding):
# `<selected-text link="<repo>@<change-id>:<path>" lines="a-b">`. The link names the commit
# that last touched the file, so the tag still resolves after a rebase, where a path plus line
# numbers drifts. The link arrives as an argument, made by `cozy git link` in the binding itself:
# a call from this file would be a parse-time dependency on the cozy module, absent on a
# bare-dotfiles host, and one unknown command here kills every Helix<->nushell call.
export def copy-link-tag [
    link: string # from `cozy git link %{buffer_name}`
    start: int # first selected line (Helix %{selection_line_start})
    end: int # last selected line (Helix %{selection_line_end})
]: string -> nothing {
    $'<selected-text link="($link)" lines="($start)-($end)">($in)</selected-text>' | pbcopy
}

# Commit in a Zellij pane that takes this pane's place until git exits (the `+ g` / `+ G`
# bindings); --add stages the whole file first. Returns only when the pane closes.
# Why the refusal: a Helix command list runs on after a failed command, so when the save
# fails, :buffer-close! fails with it and leaves the view on [scratch], whose expanded path
# lands in Helix's cwd, where git would commit whatever is staged in that repo.
# Why try, not a $env.LAST_EXIT_CODE check after git: nushell stops the script at the
# failing external, so that check never runs, and --close-on-exit hides the error at once.
# `null |` because catch passes the error record in as $in, and `input` rejects that input.
export def commit [
    file: string # buffer path (Helix %{buffer_name})
    --add # stage the whole file before committing
]: any -> nothing {
    let file = $file | path expand
    if ($file | path type) != 'file' { error make {msg: $"not a file on disk: ($file)"} }
    let dir = $file | path dirname
    if $add { ^git -C $dir add $file }
    ^zellij run --in-place --close-on-exit --block-until-exit --name commit --cwd $dir -- hx-nu -c 'try { git commit --verbose } catch { null | input "press Enter" }' | ignore
}

# The message `quick-commit` writes: the user's markers (2-char `!!` `??` `%%` at a line
# start) and CriticMarkup comments (`{>>`) that the diff adds, e.g. `gi: !! 2, {>> 1`.
# Why counts and not words: in a canvas the instructions live in the text, so the message
# only indexes the batch for Claude and for the log.
# Why 2-char only: `!!!` `???` `%%%` are the agent's, which the user does not add.
export def quick-commit-message []: string -> string {
    let added = $in | lines | where ($it =~ '^\+(?!\+\+)')
    let counts = [
        [tag pattern];
        ['!!' '^\+\s*!!(?!!)'] ['??' '^\+\s*\?\?(?!\?)'] ['%%' '^\+\s*%%(?!%)']
    ]
        | each {|t| {tag: $t.tag n: ($added | where ($it =~ $t.pattern) | length)} }
        | append {tag: '{>>' n: ($added | each { split row '{>>' | length | $in - 1 } | math sum)}
        | where n > 0
    if ($counts | is-empty) { 'gi: edit' } else {
        $counts | each { $"($in.tag) ($in.n)" } | str join ', ' | $"gi: ($in)"
    }
}

# Commit only this file with the `quick-commit-message` (the `\ k` binding): the step that
# hands a batch of canvas instructions to `\ l`, without a message to write.
# Why the pathspec on commit: it commits this file alone, never what else is staged.
export def quick-commit [file: path]: any -> nothing {
    let file = $file | path expand
    if ($file | path type) != 'file' { error make {msg: $"not a file on disk: ($file)"} }
    let root = ^git -C ($file | path dirname) rev-parse --show-toplevel
    ^git -C $root add -- $file
    let diff = ^git -C $root diff --cached -- $file
    if ($diff | is-empty) { error make {msg: $"nothing to commit in ($file | path basename)"} }
    ^git -C $root commit --quiet --message ($diff | quick-commit-message) -- $file
}

# What `\ l` sends for a file: the `!git log` line with the user's commits to it that Claude
# has not been sent, and the ref that remembers the tip once it is sent.
# The start is the tip of the last send, kept in `refs/gi/sent/<hash of the absolute path>`,
# else the last Claude commit on the file, else the file's whole history.
# Why a sent ref, not only the last Claude commit: a user commit made while Claude is
# mid-turn and sent later sits before Claude's next commit, so that range drops it.
# Why the absolute path in the hash: worktrees share refs, and one canvas path can be
# checked out in several of them.
# Why only the user's commits: Claude's own are no news to Claude; and by author, not by the
# Co-Authored-By trailer, because early agent commits carry the author only.
# Why the tip sha, not HEAD: the range is fixed at the keypress, so the remembered tip
# matches what was sent even when the line waits in Claude's queue.
# Why -C and the absolute path: Claude's cwd need not be the one of Helix.
export def tell-claude-line [file: path]: nothing -> record<line: string, ref: string, tip: string> {
    let file = $file | path expand
    let root = ^git -C ($file | path dirname) rev-parse --show-toplevel
    # Why refuse a dirty file: the line shows commits only, so Claude would read an older
    # text than the one on screen and nothing would say so.
    if (^git -C $root status --porcelain -- $file | is-not-empty) {
        error make {msg: $"($file | path basename) has uncommitted changes; commit them with `\\ k` first"}
    }
    let ref = $"refs/gi/sent/($file | hash sha256 | str substring 0..15)"
    let tip = ^git -C $root rev-parse --short=12 HEAD
    # `complete`, because a missing ref is a normal case and git exits 1 for it.
    let sent = ^git -C $root rev-parse --quiet --verify --short=12 $ref | complete | get stdout | str trim
    let sent_reachable = ($sent | is-not-empty) and (
        ^git -C $root merge-base --is-ancestor $sent HEAD | complete | get exit_code
    ) == 0
    let base = if $sent_reachable { $sent } else {
        ^git -C $root log -1 --format=%h --author='^Claude' -- $file
    }
    let range = if ($base | is-empty) { $tip } else { $"($base)..($tip)" }
    let shas = ^git -C $root log --reverse --format=%h --perl-regexp '--author=^(?!Claude)' $range -- $file | lines
    # Why refuse an empty range: the line alone starts a Claude turn, here over nothing.
    if ($shas | is-empty) {
        error make {msg: $"no new commits of yours to ($file | path basename) since ($base)"}
    }
    # Why `git show <shas>`, not `git log <range>` with the author filter: the filter needs a
    # `!` in the line, and the line runs in Claude's bash mode.
    {line: $"!git -C ($root) show ($shas | str join ' ') -- ($file)" ref: $ref tip: $tip}
}

# The pane id of the Claude session in the tab of pane `me`, from `zellij action list-panes
# --json --command`. Among several Claude panes, the one launched for this file wins
# (`gi open` puts the canvas path in its command line); errors when that leaves 0 or 2+.
export def tell-claude-pane [file: path me: int]: list<record> -> int {
    let panes = $in | where is_plugin == false
    let tab = $panes | where id == $me | get 0.tab_id
    let claudes = $panes
        | where tab_id == $tab and id != $me and ($it.pane_command? | default '' | str contains 'claude')
    let bound = $claudes | where pane_command =~ ($file | path basename)
    let pick = if ($bound | is-empty) { $claudes } else { $bound }
    if ($pick | length) != 1 {
        error make {msg: $"want one Claude pane in this tab, found ($pick | length): ($pick | get title | str join ', ')"}
    }
    $pick.0.id
}

# Type the `tell-claude-line` and Enter into the Claude pane of this tab (the `\ l` binding),
# so Claude reads the new commits without a switch to its pane; then remember the tip as sent.
# A file with uncommitted changes is committed first, as `\ k` does: one key per delivery.
# Why typed into the open pane, not a second `claude --resume`: a second process on the
# session forks its transcript, and the open pane never sees the turn (tested with -p).
# Why write-chars, not `zellij action paste`: Claude folds a bracketed paste into a chip.
export def tell-claude [file: path]: any -> nothing {
    let pane = ^zellij action list-panes --json --command
        | from json
        | tell-claude-pane $file ($env.ZELLIJ_PANE_ID | into int)
        | $"terminal_($in)"
    let root = ^git -C ($file | path expand | path dirname) rev-parse --show-toplevel
    if (^git -C $root status --porcelain -- ($file | path expand) | is-not-empty) { quick-commit $file }
    let send = tell-claude-line $file
    ^zellij action write-chars --pane-id $pane $send.line
    ^zellij action send-keys --pane-id $pane Enter
    ^git -C $root update-ref $send.ref $send.tip
}

# List the keys of one normal-mode table of config.toml (`+`, `\`) with what each does:
# the `#…→` label a prompt binding shows, else the comment at the end of the key line,
# else the first sentence of the comment above the key, else the command itself.
# Why: Helix's own `+` popup shows a multi-command key only as "[Multiple commands]".
# Why one table: `?` of each table lists only that table's own keys.
# Parses the raw text, because a TOML parser drops the comments.
export def keys [
    table: string # the key that opens the table: `+` or `\`
    config: path = (path self | path dirname | path join config.toml)
]: nothing -> table<key: string, does: string> {
    let header = $"[keys.normal.\"($table | str replace --all '\' '\\')\"]"
    let label = {|line| $line | parse --regex ':[a-z-]+ #(?<l>.*)→$' | get --optional 0.l }
    open --raw $config
    | lines
    | skip until { $in == $header }
    | skip 1
    | take until { $in starts-with '[' }
    | reduce --fold {rows: [] comment: []} {|line, acc|
        if ($line starts-with '#') {
            $acc | update comment { append ($line | str replace --regex '^#\s?' '') }
        } else if ($line =~ '^\S+ = ') {
            let kv = $line | parse --regex '^(?<key>\S+) = (?<value>.*)' | first
            let row = {
                key: ($kv.key | str trim --char "'")
                label: (do $label $line)
                trailing: ($kv.value | parse --regex r#'["'\[\]]\s+#\s(?<c>.*)$'# | get --optional 0.c)
                about: ($acc.comment | str join ' ' | split row --regex '(?<=\.)\s' | first)
                value: $kv.value
            }
            $acc | update rows { append $row } | update comment []
        } else {
            let l = do $label $line
            $acc
            | if $l != null and ($acc.rows | last | get label) == null {
                update rows { update ($in | length | $in - 1) { update label $l } }
            } else { }
            | if ($line | str trim | is-empty) { update comment [] } else { }
        }
    }
    | get rows
    | each {|r|
        let does = [$r.label $r.trailing $r.about $r.value] | where $it not-in [null '']
        {key: $r.key, does: ($does | first)}
    }
}
