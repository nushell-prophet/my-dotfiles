const CLAUDE_MD = (path self | path dirname | path join todo-claude-md-template.md)

# list active todo files
export def lstd [] {
    'todo' | path exists | if not $in { return }

    ls todo
    | sort-by modified -r
    | where type == file
    | where name =~ '\.md$'
    | insert status {|i|
        open --raw $i.name
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
    let todo_folder_is_new = if ('todo' | path exists) { false } else {
        mkdir todo
        true
    }

    if not ('todo/CLAUDE.md' | path exists) {
        cp $CLAUDE_MD todo/CLAUDE.md
    }

    let date = date now | format date '%J-%Q'

    let path = $'todo/($date).md'

    let $frontmatter = {
        status: 'draft'
        created: $date
        updated: $date
    }
        | to yaml
        | str replace --all $date $'($date) #yyyyMMdd-hhmmss'
        | str replace 'status: draft' 'status: draft #draft | in_progress | completed | rejected'
        | $"---\n($in)---\n\n"

    if not ($path | path exists) {
        $frontmatter | save --raw $path
    }

    hx +7 $path

    # check if the file wasn't modified
    if ($path | path exists) {
        open --raw $path
        | if $in == $frontmatter {
            rm $path
            if $todo_folder_is_new { rm --recursive todo/ }
        }
    }
}
