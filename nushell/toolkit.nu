# Nushell toolkit - utility commands for maintenance
export def main [] { }

const history_path = $nu.history-path | str replace -r '\.txt$' '.sqlite3'

# Recover corrupted SQLite history database
export def "main history recover" []: nothing -> nothing {
    let dump_file = 'history_dump_recover.sql'
    let output_file = 'history_recovered.sqlite3'

    if ($dump_file | path exists) { rm $dump_file }

    # Force WAL data into main database before recovery
    sqlite3 $history_path "PRAGMA wal_checkpoint(TRUNCATE);"

    sqlite3 $history_path ".recover" | save -f $dump_file
    print 'dump is made'

    # Create recovered database with a new name
    if ($output_file | path exists) { rm $output_file }
    open $dump_file | sqlite3 $output_file

    sqlite3 $output_file "PRAGMA journal_mode=WAL;" | print

    # check
    sqlite3 $output_file "PRAGMA journal_mode;" | print

    print $"Recovered database saved to ($output_file)"
    print $"To use it: cp ($output_file) history.sqlite3"
}

# Import history from SQL backup file
export def "main history import" [
    sql_file: path = "history-backups/history_back.sql" # SQL dump file to import
]: nothing -> nothing {
    let output_file = 'history_imported.sqlite3'

    if not ($sql_file | path exists) {
        error make {msg: $"SQL file not found: ($sql_file)"}
    }

    if ($output_file | path exists) { rm $output_file }

    open $sql_file | sqlite3 $output_file

    sqlite3 $output_file "PRAGMA journal_mode=WAL;" | print

    let count = sqlite3 $output_file "SELECT COUNT(*) FROM history;"
    print $"Imported ($count) history entries to ($output_file)"
    print $"To use it: cp ($output_file) history.sqlite3"
}

# Backup Nushell history database to timestamped SQL dump
export def "main history backup" []: nothing -> nothing {
    let hist_backups_dir = '~/.config/nushell/history-backups/' | path expand

    date now
    | format date '%J_%Q'
    | [$hist_backups_dir $in]
    | path join 
    | mkdir $in

    # Force WAL data into main database before backup
    sqlite3 $history_path "PRAGMA wal_checkpoint(TRUNCATE);"

    sqlite3 $history_path ".dump history"
    | save ($hist_backups_dir | path join 'history_back.sql') -f

    print $"Backup saved to ($hist_backups_dir)/history_back.sql"
}
