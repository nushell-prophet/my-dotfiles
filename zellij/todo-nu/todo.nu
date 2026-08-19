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

    let date = date now | format date '%J'

    # Why: the name is the bare date; a second todo the same day gets -1, -2, …
    let path = 0..
        | each {|i| if $i == 0 { $'todo/($date).md' } else { $'todo/($date)-($i).md' } }
        | where {|p| not ($p | path exists) }
        | first

    # Not `to yaml` because: a bare date comes back quoted, so the trailing #hint
    # lands inside the value instead of being a yaml comment
    let $frontmatter = $"---
status: draft #draft | in_progress | completed | rejected
created: '($date)' #yyyyMMdd
updated: '($date)' #yyyyMMdd
---

"

    $frontmatter | save --raw $path

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
