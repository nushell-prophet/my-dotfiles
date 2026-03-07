#!/usr/bin/env nu

const todo = path self | path expand | path dirname | path join todo.nu

use $todo create-todo

create-todo
