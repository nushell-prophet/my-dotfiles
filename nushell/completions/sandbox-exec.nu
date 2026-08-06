# Nushell completions for sandbox-exec - execute within a sandbox (macOS)

def "nu-complete sandbox-exec profiles" [] {
    ls /usr/share/sandbox/*.sb
    | get name
    | path basename
    | each {|f| $f | str replace '.sb' '' }
    | sort
    | each {|name| {value: $name description: $"Profile: ($name)"} }
}

export extern main [
    command: string # Command to execute in sandbox
    ...arguments: string # Arguments to command
    -f: path # Read profile from file
    -n: string@"nu-complete sandbox-exec profiles" # Use pre-defined profile
    -p: string # Specify profile string on command line
    -D: string # Set profile parameter key=value
]
