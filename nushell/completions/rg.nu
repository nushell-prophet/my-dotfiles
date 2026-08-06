# Nushell completions for rg (ripgrep) 13.0.0 - recursive regex search that respects gitignore

# `rg --type-list` prints "name: glob1, glob2", so the globs are the most informative description for a type name.
# The caret forces the external binary; without it this would recurse into the extern below.
def "nu-complete rg type" [] {
    ^rg --type-list
    | lines
    | parse --regex '^(?<value>[^:]+):\s*(?<description>.*)$'
}

# Only -t/--type accepts the special "all"; --type-not and --type-clear do not.
def "nu-complete rg type or all" [] {
    [[value description]; [all "every file type ripgrep knows, i.e. whitelist mode"]]
    | append (nu-complete rg type)
}

# The --colors help defines a grammar, not a value list: {type}:{attribute}:{value}, plus {type}:none to clear.
# Expanding it here is what makes the flag discoverable, since the legal parts are never printed together anywhere else.
def "nu-complete rg colors" [] {
    let colors = [red blue green cyan magenta yellow white black]
    let styles = [nobold bold nointense intense nounderline underline]

    [path line column match]
    | each {|type|
        [$"($type):none"]
        | append ($colors | each {|c| [$"($type):fg:($c)" $"($type):bg:($c)"]} | flatten)
        | append ($styles | each {|s| $"($type):style:($s)"})
    }
    | flatten
}

# --sort and --sortr take the same value set, so it lives in one place.
const rg_sort_by = [none path modified accessed created]

export extern main [
    pattern?: string # regex to search for; use -e/--regexp for a pattern starting with a dash
    ...paths: path # files or directories to search; directories are searched recursively

    # Pattern sources and matching
    --regexp (-e): string # pattern to search for; repeatable, and safe for patterns starting with a dash
    --file (-f): path # read patterns from a file, one per line; repeatable
    --fixed-strings (-F) # treat the pattern as a literal string, not a regex
    --no-fixed-strings # treat the pattern as a regex again
    --ignore-case (-i) # match case insensitively
    --case-sensitive (-s) # match case sensitively
    --smart-case (-S) # case insensitive if the pattern is all lowercase, case sensitive otherwise
    --word-regexp (-w) # only show matches surrounded by word boundaries
    --line-regexp (-x) # only show matches that span a whole line
    --invert-match (-v) # show lines that do NOT match
    --multiline (-U) # allow a match to span line terminators
    --no-multiline # keep matches within one line
    --multiline-dotall # let '.' match newlines when multiline search is on
    --no-multiline-dotall # keep '.' from matching newlines
    --crlf # treat CRLF as the line terminator so '$' matches before it
    --no-crlf # treat only LF as the line terminator
    --null-data # use NUL as the line terminator; implies -a/--text
    --unicode # enable Unicode mode in all regexes (default)
    --no-unicode # disable Unicode mode: ASCII-only classes, no \p{...}
    --pcre2-unicode # alias for --unicode
    --no-pcre2-unicode # DEPRECATED alias for --no-unicode

    # Regex engine
    --engine: string@[default pcre2 auto] # which regex engine to use
    --pcre2 (-P) # use PCRE2: look-around and backreferences
    --no-pcre2 # use the default regex engine
    --auto-hybrid-regex # DEPRECATED, use --engine auto
    --no-auto-hybrid-regex # disable --auto-hybrid-regex
    --regex-size-limit: string # size cap for the compiled regex, e.g. 50K, 80M (default 10M)
    --dfa-size-limit: string # size cap for the regex DFA, e.g. 50K, 80M (default 10M)

    # What to print
    --count (-c) # print only the count of matching lines per file
    --count-matches # print only the count of individual matches per file
    --include-zero # with --count/--count-matches, also print files with zero matches
    --files-with-matches (-l) # print only the paths that contain at least one match
    --files-without-match # print only the paths that contain no match
    --files # print each file that would be searched, without searching
    --json # print results as JSON Lines
    --no-json # print results as plain text
    --only-matching (-o) # print only the matched part of each line
    --passthru # print every line, matching or not
    --quiet (-q) # print nothing; stop at the first match and use the exit code
    --replace (-r): string # replace each match with this text in the output; supports $1, $name
    --stats # print aggregate search statistics at the end
    --no-stats # do not print search statistics
    --vimgrep # one line per match with line and column numbers
    --pretty (-p) # alias for --color always --heading --line-number

    # Output format and fields
    --color: string@[never auto always ansi] # when to colorize output
    --colors: string@"nu-complete rg colors" # color or style for one output field; repeatable
    --column # show 1-based column numbers; implies --line-number
    --no-column # hide column numbers
    --line-number (-n) # show 1-based line numbers
    --no-line-number (-N) # hide line numbers
    --byte-offset (-b) # print the 0-based byte offset before each output line
    --heading # print the file path above each cluster of matches
    --no-heading # print the file path as a prefix on every matched line
    --with-filename (-H) # always show the file path
    --no-filename (-I) # never show the file path
    --null (-0) # follow every printed file path with a NUL byte, for xargs
    --max-columns (-M): int # skip lines longer than this many bytes
    --max-columns-preview # with --max-columns, show the truncated head of the line
    --no-max-columns-preview # with --max-columns, replace long lines with a message
    --trim # strip leading ASCII whitespace from each printed line
    --no-trim # keep leading whitespace
    --path-separator: string # single byte used to separate path components in output
    --field-context-separator: string # delimiter between fields on context lines (default -)
    --field-match-separator: string # delimiter between fields on matched lines (default -)
    --context-separator: string # marker between non-contiguous context blocks (default --)
    --no-context-separator # no marker between context blocks
    --sort: string@$rg_sort_by # sort results ascending; forces single-threaded search
    --sortr: string@$rg_sort_by # sort results descending; forces single-threaded search

    # Context lines
    --after-context (-A): int # show NUM lines after each match
    --before-context (-B): int # show NUM lines before each match
    --context (-C): int # show NUM lines before and after each match

    # File types
    --type (-t): string@"nu-complete rg type or all" # only search files of this type; repeatable
    --type-not (-T): string@"nu-complete rg type" # skip files of this type; repeatable
    --type-add: string@"nu-complete rg type" # add a glob to a type, "name:*.ext" or "name:include:a,b"
    --type-clear: string@"nu-complete rg type" # drop the built-in globs of this type
    --type-list # list every known file type and its globs

    # Which paths get walked
    --glob (-g): string # include or exclude paths matching this gitignore-style glob; ! negates
    --iglob: string # like --glob, matched case insensitively
    --glob-case-insensitive # treat every --glob as --iglob
    --no-glob-case-insensitive # match --glob case sensitively
    --hidden (-.) # search hidden files and directories
    --no-hidden # skip hidden files and directories
    --follow (-L) # follow symbolic links while walking
    --no-follow # do not follow symbolic links
    --max-depth: int # descend at most NUM levels below the given paths
    --max-filesize: string # skip files larger than this, e.g. 50K, 80M
    --one-file-system # do not cross file system boundaries
    --no-one-file-system # allow crossing file system boundaries
    --unrestricted (-u) # less smart searching; -uu adds hidden files, -uuu adds binary files

    # Ignore rules
    --ignore # respect ignore files (default)
    --no-ignore # ignore .gitignore, .ignore and friends entirely
    --ignore-dot # respect .ignore files (default)
    --no-ignore-dot # skip .ignore files
    --ignore-exclude # respect repo-local excludes like .git/info/exclude (default)
    --no-ignore-exclude # skip repo-local excludes
    --ignore-global # respect global ignore files, e.g. core.excludesFile (default)
    --no-ignore-global # skip global ignore files
    --ignore-parent # respect ignore files in parent directories (default)
    --no-ignore-parent # skip ignore files in parent directories
    --ignore-vcs # respect .gitignore and other VCS ignore files (default)
    --no-ignore-vcs # skip VCS ignore files
    --ignore-files # honour --ignore-file flags (default)
    --no-ignore-files # discard every --ignore-file flag, even later ones
    --ignore-file: path # extra file of gitignore-format rules; repeatable, later wins
    --ignore-file-case-insensitive # match ignore-file rules case insensitively; slower
    --no-ignore-file-case-insensitive # match ignore-file rules case sensitively
    --ignore-messages # report errors from parsing ignore files (default)
    --no-ignore-messages # suppress errors from parsing ignore files
    --require-git # apply git ignore rules only inside a git repository (default)
    --no-require-git # apply git ignore rules even outside a git repository

    # Binary files, decompression and preprocessing
    --text (-a) # search binary files as if they were text
    --no-text # restore binary file detection
    --binary # keep searching past a NUL byte instead of skipping the file
    --no-binary # stop at the first NUL byte (default)
    --search-zip (-z) # search inside gzip, bzip2, xz, LZ4, LZMA, Brotli and Zstd files
    --no-search-zip # do not decompress files before searching
    --pre: string # run this command on each file and search its stdout instead
    --no-pre # disable the --pre preprocessor
    --pre-glob: string # only hand files matching this glob to --pre; repeatable
    --encoding (-E): string@[auto none] # text encoding for every file searched; any WHATWG label also works
    --no-encoding # disable transcoding, including BOM sniffing

    # Performance and buffering
    --threads (-j): int # approximate thread count; 0 lets ripgrep decide
    --max-count (-m): int # stop after NUM matching lines per file
    --mmap # use memory maps when they look faster
    --no-mmap # never use memory maps
    --block-buffered # force block buffering, the default when stdout is a pipe or file
    --no-block-buffered # go back to detecting the buffering strategy automatically
    --line-buffered # flush every matching line immediately, useful in a pipeline
    --no-line-buffered # go back to detecting the buffering strategy automatically

    # Messages and meta
    --messages # report errors from opening and reading files (default)
    --no-messages # suppress errors from opening and reading files
    --no-config # ignore RIPGREP_CONFIG_PATH and any config file
    --debug # show debug messages, e.g. why a file was skipped
    --trace # even more output than --debug; implies it
    --pcre2-version # print the PCRE2 version in use and exit
    --version (-V) # print version
]
