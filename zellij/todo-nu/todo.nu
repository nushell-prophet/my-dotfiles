const CLAUDE_MD = (path self | path dirname | path join todo-claude-md-template.md)

# list active todo files
export def lstd [] {
    'todo' | path exists | if not $in { return }

    ls todo
    | sort-by modified -r
    | where type == file
    | where name =~ '\.md$'
    | insert status {|i|
        open $i.name
        | split row -r "---\n?"
        | get 1?
        | try { from yaml | get status -o }
        | default "draft"
    }
    | where status not-in ["completed" "rejected"]
    | get name
    | to text
    | fzf --reverse --preview 'bat --wrap=auto --terminal-width=$FZF_PREVIEW_COLUMNS --style=numbers --color=always {}' --bind 'ctrl-e:execute-silent(zellij edit {})'
    | if ($in | is-not-empty) { tee { pbcopy } }
}

export def create-todo [] {
    let todo_folder_existed = if ('todo' | path exists) { true } else {
        mkdir todo
        cp $CLAUDE_MD todo
        false
    }
    # cd todo

    let date = date now | format date '%J-%Q'

    let path = $'todo/($date).md'

    let $frontmatter = {
        status: 'draft'
        created: $date
        updated: $date
    }
        | to yaml
        | str replace --all $date $'($date) #yyyyMMdd-hhmmss'
        | $"---\n($in)---\n\n"

    if not ($path | path exists) {
        $frontmatter | save --raw $path
    }

    hx +7 $path

    # check if the file wasn't modified
    open $path --raw
    | if $in == $frontmatter {
        rm $path
        if not $todo_folder_existed { rm todo -r }
    }
}
