# Nushell Environment Config File

def create_left_prompt [] {
    let dir = do -i { pwd | path relative-to $nu.home-dir }
        | match $in {
            null => (pwd)
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

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| null }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "" }

# Collapse the 2-line prompt to a single newline for previously entered commands
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

# Directories to search for plugin binaries when calling `plugin add`
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

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
        '~/.local/bin'
        '~/Applications/WezTerm.app/Contents/MacOS'
        '~/Applications/kitty.app/Contents/MacOS'
    ]
    | path expand
    | str trim
    | where { path exists }
    | uniq
)

$env.TOPIARY_CONFIG_FILE = ($env.XDG_CONFIG_HOME | path join topiary languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = ($env.XDG_CONFIG_HOME | path join topiary languages)

$env.EDITOR = 'hx'

alias `:q` = exit
alias vd = vd --config=($env.XDG_CONFIG_HOME | path join visidata config.py) # should be fixed in 3.5
