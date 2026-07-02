$env.config.hooks = {
    pre_prompt: [
        {
            # Tag the last history row with ` #exit_<code>` when a command fails, and
            # strip the tag again once the same command later succeeds. Makes failed
            # commands visible in history search.
            #
            # The hook is ugly: I don't like rewriting history, and it has rough edges.
            # E.g. pressing Up on a failed command in the REPL, I first have to delete
            # the ` #exit_<code>` suffix before I can edit and rerun the line. Keeping it
            # for now anyway.
            #
            # Coupling: nu-goodies capture.nu (match-history-command, completions-copy-out)
            # strips this tag so `copy-out` still matches the untagged on-screen command.
            # If this hook is ever removed, restore capture.nu to its clean, tag-unaware state.
            if ($nu.history-path =~ '\.sqlite3$') {
                let exit_code = $env.LAST_EXIT_CODE
                let sid = history session
                if $exit_code >= 1 {
                    open $nu.history-path
                    | query db $"UPDATE history SET command_line = CASE WHEN command_line LIKE '% #exit_%' THEN SUBSTR\(command_line, 1, INSTR\(command_line, ' #exit_'\) - 1\) || ' #exit_($exit_code)' ELSE command_line || ' #exit_($exit_code)' END WHERE id = \(SELECT MAX\(id\) FROM history WHERE session_id = ($sid)\)"
                } else {
                    # Strip #exit_ from all entries matching the last command
                    open $nu.history-path
                    | query db $"UPDATE history SET command_line = SUBSTR\(command_line, 1, INSTR\(command_line, ' #exit_'\) - 1\) WHERE command_line LIKE \(SELECT CASE WHEN command_line LIKE '% #exit_%' THEN SUBSTR\(command_line, 1, INSTR\(command_line, ' #exit_'\) - 1\) ELSE command_line END FROM history WHERE id = \(SELECT MAX\(id\) FROM history WHERE session_id = ($sid)\)\) || ' #exit_%'"
                }
            }
        }
    ]
    pre_execution: [{ null }] # run before the repl input is run
    env_change: {
        PWD: [
            {
                # seems like the hook below is redundant as env_change presupposes change
                # condition: {|_, after| $_ != null}
                code: "if $env.ZELLIJ_SESSION_NAME? != null {
                  let base = pwd | path basename | str replace -r '^-+' '';
                  let tabs = zellij action query-tab-names | lines;

                  let used = $tabs
                  | where $it =~ ('^' + $base + '(·|$)')
                  | each {
                      split row '·'
                      | last
                      | if $in == $base { 1 } else { into int }
                  }
                  | sort;

                  let name = if ($used | is-empty) or (1 not-in $used) {
                      $base
                  } else {
                      let n = 2.. | where { $in not-in $used } | first;
                      $'($base)·($n)'
                  };

                  zellij action rename-tab $name
              }"
            }
        ]
    }

    display_output: {
        metadata access {|meta|
            match $meta.content_type? {
                "application/x-nuscript" | "application/x-nuon" | "text/x-nushell" => { nu-highlight }
                "application/json" => { ^bat --language=json --color=always --style=plain --paging=never }
                _ => { }
            }
        }
        | if (term size).columns >= 100 { table -e } else { table }
    }

    # run to display the output of a pipeline
    command_not_found: { null } # return an error message when a command is not found
}
