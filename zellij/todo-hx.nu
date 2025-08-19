#!/usr/bin/env nu

mkdir todo

cd todo

let date = date now | format date '%+' | str substring ..9 | str replace --all -r '[^\dT]' '' 

let index = glob $'($date)*'
| if ($in | is-empty) {1} else {
    let list = $in;

    $list
    | sort
    | last
    | parse -r '\d{8}-(\d+)'
    | get capture0?.0?
    | default 0
    | into int
    | $in + 1
    | append ($list | length | $in + 1)
    | math max
}

let path = $'($date)-($index).md'

hx $path

cd ..

if (ls 'todo' | is-empty) {rm 'todo'}
