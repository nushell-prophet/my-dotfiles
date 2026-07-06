# Preview for the Ctrl+F history picker (see config.nu): shows when/where the
# command ran (timestamp, duration, exit status, cwd — fetched from the history
# db by id) above the syntax-highlighted command.
# fzf invokes it as: nu -n --no-std-lib fzf-hist-preview.nu <db> {1} {2..}

def main [
    db: path # the sqlite history database
    id: int # history row id (fzf field 1)
    command: string # the command text (fzf fields 2..)
] {
    let meta = open $db
        | query db "SELECT start_timestamp, cwd, duration_ms, exit_status FROM history WHERE id = :id" --params {id: $id}
        | first

    # start_timestamp is unix milliseconds; into datetime reads ints as nanoseconds
    let when = $meta.start_timestamp * 1_000_000 | into datetime | format date '%y-%m-%d %H:%M:%S'
    let dur = $meta.duration_ms | if $in == null { '?' } else { into duration --unit ms }
    let status = $meta.exit_status | default '?'
    print $"(ansi dark_gray)($when) • ($dur) • exit ($status) • ($meta.cwd)(ansi reset)"
    $command | nu-highlight
}
