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

const translit = {
    а: a б: b в: v г: g д: d е: e ё: e ж: zh з: z и: i й: y к: k л: l м: m
    н: n о: o п: p р: r с: s т: t у: u ф: f х: kh ц: ts ч: ch ш: sh щ: shch
    ъ: '' ы: y ь: '' э: e ю: yu я: ya
}

# The file-name part of a title: Cyrillic transliterated, anything else that is not
# a latin letter or a digit collapsed to `-`.
export def title-slug []: string -> string {
    str lowercase
    | split chars
    | each {|c| $translit | get --optional $c | default $c }
    | str join
    | str replace --all --regex '[^a-z0-9]+' '-'
    | str trim --char '-'
}

export def create-todo [] {
    # Why asked before anything is written: the path is final while the file is open,
    # so it can be copied from the editor without a `:mv` first.
    let title = input 'title: ' | str trim
    let slug = $title | title-slug

    let todo_folder_is_new = if ('todo' | path exists) { false } else {
        mkdir todo
        true
    }

    let date = date now | format date '%J'
    let base = if ($slug | is-empty) { $date } else { $'($date)-($slug)' }

    # Why: a second todo with the same name the same day gets -1, -2, …
    let path = 0..
        | each {|i| if $i == 0 { $'todo/($base).md' } else { $'todo/($base)-($i).md' } }
        | where {|p| not ($p | path exists) }
        | first

    let heading = if ($title | is-empty) { '' } else { $"\n# ($title)\n" }

    # Not `to yaml` because: a bare date comes back quoted, so the trailing #hint
    # lands inside the value instead of being a yaml comment
    # Why the second empty line: the cursor must land on a real line. Without it the last
    # line is the phantom line after the final newline, where helix computes no indent, so
    # list continuation lines start at column 0.
    let $template = $"---
status: draft #draft | in_progress | completed | rejected
agents-mode: co-editing #read-only | grammar-fixes | co-editing
updated: '($date)' #yyyyMMdd
---
($heading)

"

    $template | save --raw $path

    hx $'+($template | lines | length)' $path

    # check if the file wasn't modified
    if ($path | path exists) {
        open --raw $path
        | if $in == $template {
            rm $path
            if $todo_folder_is_new { rm --recursive todo/ }
        }
    }
}
