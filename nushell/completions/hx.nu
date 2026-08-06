# Nushell completions for hx — the Helix editor
# Built against helix 25.07.1. Flags come from `hx --help` of that build.

# `--health` takes a language name as readily as one of the three keywords, and
# helix knows ~300 languages, so the list is worth pulling from the binary.
def "nu-complete hx health" [] {
    let keywords = [
        {value: all description: "Every category"}
        {value: languages description: "Language support table"}
        {value: clipboard description: "Clipboard provider"}
    ]

    # Why COLUMNS: helix sizes this table to the terminal and truncates the
    # name column to fit, so at a normal width 37 languages come back as
    # "typescrip…" and complete to nothing. Widening the reported terminal for
    # this one call is what makes the names whole.
    #
    # Why the first token rather than a column parse: the header is truncated
    # by the same logic, so column names and offsets shift with the width. The
    # language name is always the first field on the line.
    let languages = with-env {COLUMNS: "200"} { ^hx --health languages }
        | lines
        | skip 1
        | each { split row ' ' | first }
        | where { is-not-empty }
        | each {|l| {value: $l description: "Language"} }

    {
        options: {case_sensitive: false completion_algorithm: fuzzy sort: false}
        completions: ($keywords | append $languages)
    }
}

export extern main [
    ...files: path # file to open, as file[:row[:col]]
    --tutor # load the tutorial
    --health: string@"nu-complete hx health" # check the editor setup, by category
    --grammar (-g): string@[fetch build] # fetch or build the tree-sitter grammars in languages.toml
    --config (-c): path # configuration file to use
    -v # raise logging verbosity, up to three times
    --log: path # file to log into
    --version (-V) # print version
    --vsplit # split the given files vertically
    --hsplit # split the given files horizontally
    --working-dir (-w): path # initial working directory
]
