# # External Completions via Carapace

# $env.CARAPACE_MATCH = 1 # ignore case

# $env.config.completions.external.completer = {|spans|
#     # if the current command is an alias, get it's expansion
#     let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0 | get -o expansion)

#     # overwrite
#     let spans = (
#         if $expanded_alias != null {
#             # put the first word of the expanded alias first in the span
#             $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
#         } else {
#             $spans
#         }
#     )

#     carapace $spans.0 nushell ...$spans
#     | from json
# }
