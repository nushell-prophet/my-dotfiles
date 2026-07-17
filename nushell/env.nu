# Nushell Environment Config File

def create-left-prompt []: nothing -> string {
    # collapse $in to $mark when it sits under $base; unchanged otherwise
    let collapse = {|base mark|
        let path = $in
        do --ignore-errors { $path | path relative-to $base }
        | match $in {
            null => $path
            '' => $mark
            $rel => ([$mark $rel] | path join)
        }
    }

    let dir = pwd | do $collapse $nu.home-dir '~'

    let git_status = git status --branch --porcelain
        | complete
        | if $in.exit_code == 0 {
            $in.stdout
            | lines
            | first
            | str replace --regex '^## ' ''
            # Why: the raw line is wordy — `main...codeberg/main [ahead 26]`;
            # the upstream name is noise, so compact to starship-style `main ⇡26⇣2`
            | str replace --regex '\.\.\.\S+' ''
            | str replace 'ahead ' '⇡'
            | str replace 'behind ' '⇣'
            | str replace ', ' ''
            | str replace --regex ' \[(.+)\]$' ' $1'
        } else { '' }
        | if $in == '' { } else { $in + ' ' }

    let last_exit_code = if $env.LAST_EXIT_CODE != 0 {
        $'(ansi red_bold)($env.LAST_EXIT_CODE)(ansi reset) '
    } else { "" }

    # Why: into int because SHLVL arrives as a string when inherited from the
    # OS environment (e.g. a nu spawned outside a login shell) — without it the
    # comparison below kills the whole prompt.
    let shlvl = $env.SHLVL? | default 1 | into int
        # show only if there are more than 2 instances
        | if $in <= 2 { '' } else { $'(ansi yellow)nu($in)(ansi reset) ' }

    # hide near-instant commands
    let duration = $env.CMD_DURATION_MS | into int | if $in < 90 { '' } else { $'($in)ms ' }

    # everything after the path — built once, so the width math below and the
    # rendered prompt can't drift apart
    let tail = $'($git_status)($duration)($last_exit_code)($shlvl)'
    let width = { ansi strip | str length --grapheme-clusters } # visible width
    let max_width = (term size).columns - 2 # the `┏ ` prefix takes 2 cells

    # Why: when the line would overflow, shorten the path rather than let the
    # cap below cut off the more informative tail (git, duration, exit code).
    # Shortening is a last resort: the full path is what wezterm quick-select
    # copies, so it stays whole while there is space. That is also why the
    # workspace mount (in the container it sits at the host's long absolute
    # path, not under ~ there) collapses to ~ws only here, not unconditionally.
    # Then fish-style (~/g/a/nu-multiproof) if ~ws alone is not enough.
    let fits = {|d| (($d | do $width) + 1 + ($tail | do $width)) <= $max_width }
    let dir = if (do $fits $dir) { $dir } else {
        let dir = $env.WORKSPACE_DIR?
            | match $in {
                null => $dir
                $ws => ($dir | do $collapse $ws '~ws')
            }
        if (do $fits $dir) { $dir } else {
            $dir | split row (char path_sep)
            | drop 1
            # ~ and ~ws markers stay whole; dot-dirs keep two chars
            | each {|c| if ($c starts-with '~') { $c } else { $c | str substring --grapheme-clusters 0..(if ($c starts-with '.') { 1 } else { 0 }) } }
            | append ($dir | path basename)
            | str join (char path_sep)
        }
    }

    let path_color = if (is-admin) { ansi red_bold } else { ansi green_italic }
    let separator_color = if (is-admin) { ansi light_red_bold } else { ansi white }
    let path_segment = $"($path_color)($dir)(ansi reset)"
        | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"

    # Why: the prompt must never be wider than one terminal line. str substring
    # would count the invisible ansi codes, so measure the stripped text and
    # drop the colors in the rare overflow case.
    let longprompt = $'($path_segment) ($tail)'
        | if ($in | do $width) <= $max_width { } else {
            ($in | ansi strip | str substring --grapheme-clusters 0..<($max_width - 1)) + '…'
        }

    # nu-goodies/capture.nu (copy-out, delete-prompts, zellij-to-png) parses
    # this exact shape from scrollback (`\n┏ …\n┗━> cmd`) — keep in sync.
    $'(char nl)(ansi grey)┏ (ansi reset)($longprompt)'
    | append $'(ansi grey)┗━(ansi reset)'
    | str join (char nl)
}

$env.PROMPT_COMMAND = {|| create-left-prompt }
$env.PROMPT_COMMAND_RIGHT = {|| null }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "" }

# Collapse the 2-line prompt to a single newline for previously entered commands
# (re-enabling changes the scrollback shape nu-goodies/capture.nu parses)
# $env.TRANSIENT_PROMPT_COMMAND = {|| "\n" }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Why: NUPM_HOME below reads XDG_DATA_HOME, and TOPIARY_* below
# read XDG_CONFIG_HOME. cozy bakes CONFIG/DATA/CACHE into the OS env
# (Dockerfile ENV or /etc/sandbox-persistent.sh), but on a fresh shell or
# macOS host they aren't set, and nu would crash with "Cannot find column
# XDG_*_HOME". Honor an existing value if present (so a baked or host value
# wins), fall back to the XDG-spec defaults. All four use the same pattern:
# an unconditional set would silently override whatever cozy baked.
$env.XDG_STATE_HOME = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
$env.XDG_CACHE_HOME = ($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache"))
$env.XDG_DATA_HOME = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config"))
$env.NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")

# Directories to search for scripts when calling source or use
const NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
    ($nu.data-dir | path join 'completions')
]

# Directories to search for plugin binaries when calling `plugin add`
const NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

$env.PATH = (
    $env.PATH
    # Why: `nu --mcp` skips the startup string→list PATH conversion, so PATH
    # arrives here as one colon-joined string; `where { path exists }` below
    # would drop it whole, leaving only the prepended dirs (no git, no prompt).
    | if ($in | describe) == string { split row (char esep) } else { }
    | prepend [
        ($env.NUPM_HOME | path join "scripts")
        ($env.NUPM_HOME | path join "modules")
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
    | where { path exists }
    | uniq
)

$env.TOPIARY_CONFIG_FILE = ($env.XDG_CONFIG_HOME | path join topiary languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = ($env.XDG_CONFIG_HOME | path join topiary languages)

$env.EDITOR = 'hx'

alias `:q` = exit
