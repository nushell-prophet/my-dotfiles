# List source for the Ctrl+F history picker (see config.nu): prints deduped
# history as `id<tab>command_line` records, NUL-separated, newest first, for
# fzf --read0. fzf runs it on start and on the alt-c cwd toggle (reload).
# Why the db path is a parameter: fzf spawns this under `nu -n`, where
# $nu.history-path resolves to the plaintext default, not the sqlite file.

# ROW_NUMBER dedup keeps each command's latest run
def main [
    db: path # the sqlite history database
    --cwd # only entries recorded in the current directory
] {
    let sql = "WITH ordered AS (
            SELECT id, command_line,
                ROW_NUMBER() OVER (PARTITION BY command_line ORDER BY id DESC) AS rn
            FROM history WHERE_CWD
        )
        SELECT id, command_line FROM ordered WHERE rn = 1 ORDER BY id DESC"
        | str replace 'WHERE_CWD' (if $cwd { 'WHERE cwd = :cwd' } else { '' })

    open $db
    | if $cwd { query db $sql --params {cwd: $env.PWD} } else { query db $sql }
    | each { $"($in.id)\t($in.command_line)" }
    | str join (char nul)
    | print --no-newline
}
