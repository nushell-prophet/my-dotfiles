# Nushell Environment Config File

def create_left_prompt [] {
    let dir = do -i { $env.PWD | path relative-to $nu.home-path }
    | match $in {
        null => $env.PWD
        '' => '~'
        $relative_pwd => ([~ $relative_pwd] | path join)
    }

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_italic })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi white })
    let path_segment = $"($path_color)($dir)(ansi reset)"
    | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"

    let git_status = git status --branch --porcelain
    | complete
    | if $in.exit_code == 0 {
        $in.stdout
        | lines
        | first
        | str replace -r '^## ' ''
    } else { '' }

    $'(char nl)(ansi grey)┏ (ansi reset)($path_segment) ($git_status)'
    | append $'(ansi grey)┗━(ansi reset)'
    | str join (char nl)
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment: closure = {
        [
            (ansi reset)
            (ansi magenta)
            (date now | format date '%H:%M') # try to respect user's locale
        ]
        | str join
        | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)"
        | $'($in)(ansi reset)'
    }

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {
        $'(ansi rb)($env.LAST_EXIT_CODE)'
    } else { "" }

    [$last_exit_code (char space) (ansi yellow) (last-10-commands) (char space) ($env.SHLVL? | default 1 | $in - 1)]
    | str join
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# FIXME: This default is not implemented in rust code as of 2023-09-08.
$env.PROMPT_COMMAND_RIGHT = {|| null }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "" }

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
$env.TRANSIENT_PROMPT_COMMAND = {|| "\n" }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
        to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
        to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
    }
}

$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_STATE_HOME = ($env.HOME | path join ".local" "state")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")
$env.NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
# An alternate way to add entries to $env.PATH is to use the custom command `path add`
# which is built into the nushell stdlib:
# use std "path add"
# $env.PATH = ($env.PATH | split row (char esep))
# path add /some/path
# path add ($env.CARGO_HOME | path join "bin")
# path add ($env.HOME | path join ".local" "bin")

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend [
        ($env.NUPM_HOME | path join "scripts")
        ($env.NUPM_HOME | path join "modules")
        '/opt/homebrew/opt/curl/bin'
        '~/.docker/bin'
        '~/.cargo/bin'
        '~/miniconda3/bin'
        '~/miniconda3/condabin'
        '/opt/homebrew/bin'
        '/opt/homebrew/sbin'
        '/usr/local/bin'
        '/usr/local/go/bin'
        '~/go/bin'
        '~/.local/bin'
        '~/.config/nvm'
        '~/.config/nvm/versions/node/v22.17.0/bin'
        '~/Applications/WezTerm.app/Contents/MacOS'
        '~/Applications/kitty.app/Contents/MacOS'
        '~/.claude/local/'
    ]
    | str trim
    | where {|i| $i | path exists }
    | uniq
)

$env.TOPIARY_CONFIG_FILE = ($env.XDG_CONFIG_HOME | path join topiary languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = ($env.XDG_CONFIG_HOME | path join topiary languages)

# To load from a custom file you can use:
# source ($nu.default-config-dir | path join 'custom.nu')

$env.EDITOR = 'hx'

alias `:q` = exit
alias vd = vd --config=($env.XDG_CONFIG_HOME | path join visidata config.py) # should be fixed in 3.5
