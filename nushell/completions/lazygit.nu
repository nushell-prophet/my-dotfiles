# Nushell completions for lazygit — a terminal UI for git
# Built against lazygit 0.63.0. Flags come from `lazygit --help` of that build.
#
# Only the long forms of lazygit's multi-letter short flags are declared
# (--print-config-dir, --use-config-dir, --use-config-file, --screen-mode).
# lazygit spells those -cd, -ucd, -ucf and -sm, which a Nushell signature
# cannot express: the (-x) short form holds exactly one character. The long
# forms are what the tool documents anyway, and both reach the same flag.

const panels = [
    {value: status description: "Repository status"}
    {value: branch description: "Branches, local and remote"}
    {value: log description: "Commit log"}
    {value: stash description: "Stashed changes"}
]

export extern main [
    panel?: string@$panels # panel to focus on opening; ignored when --filter is passed
    --path (-p): path # path of the git repo, as --work-tree=<path> --git-dir=<path>/.git/
    --filter (-f): path # filter commits, reflog and stash by this path
    --version (-v) # print the current version
    --debug (-d) # run in debug mode with logging; LOG_LEVEL sets the level
    --logs (-l) # tail lazygit logs, for a second terminal beside --debug
    --profile # start the profiler and serve it on http port 6060
    --config (-c) # print the default config
    --print-config-dir # print the config directory
    --use-config-dir: path # override the default config directory
    --work-tree (-w): path # equivalent of git --work-tree
    --git-dir (-g): path # equivalent of git --git-dir
    --use-config-file: string # comma-separated list of custom config files
    --screen-mode: string@[normal half full] # initial size of the focused panel
]

export extern "lazygit completion" [
    shell: string@[bash zsh] # shell to generate a completion script for
]
