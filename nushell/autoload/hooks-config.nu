$env.config.hooks = {
    pre_prompt: [{ null }] # run before the prompt is shown
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
