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
    mkdir todo

    # cd todo

    let date = date now | format date '%J-%Q'

    let path = $'todo/($date).md'

    let $frontmatter = {
        status: 'draft'
        created: $date
        updated: $date
    }
    | to yaml
    | str replace -r "\n$" ""
    | prepend '---'
    | append '---'
    | to text

    mkdir todo/

    if not ($path | path exists) {
        $frontmatter | save $path
    }

    hx $path

    # check if the file wasn't modified
    open $path
    | if $in == $frontmatter { rm $path }

    if (ls 'todo' | is-empty) { rm 'todo' } else {
        cp $CLAUDE_MD todo/CLAUDE.md
    }
}
