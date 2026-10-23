
(setext_heading (paragraph) @markup.heading.1 (setext_h1_underline) @markup.heading.marker)
(setext_heading (paragraph) @markup.heading.2 (setext_h2_underline) @markup.heading.marker)

(atx_heading (atx_h1_marker) @markup.heading.marker) @markup.heading.1
(atx_heading (atx_h2_marker) @markup.heading.marker) @markup.heading.2
(atx_heading (atx_h3_marker) @markup.heading.marker) @markup.heading.3
(atx_heading (atx_h4_marker) @markup.heading.marker) @markup.heading.4
(atx_heading (atx_h5_marker) @markup.heading.marker) @markup.heading.5
(atx_heading (atx_h6_marker) @markup.heading.marker) @markup.heading.6

[
  (indented_code_block)
  (fenced_code_block)
] @markup.raw.block

(info_string) @label

[
  (fenced_code_block_delimiter)
] @punctuation.bracket

[
  (link_destination)
] @markup.link.url

[
  (link_label)
] @markup.link.label

[
  (list_marker_plus)
  (list_marker_minus)
  (list_marker_star)
] @markup.list.unnumbered

[
  (list_marker_dot)
  (list_marker_parenthesis)
] @markup.list.numbered

(task_list_marker_checked) @markup.list.checked
(task_list_marker_unchecked) @markup.list.unchecked

(thematic_break) @punctuation.special

[
  (block_continuation)
  (block_quote_marker)
] @punctuation.special

[
  (backslash_escape)
] @string.escape

(block_quote) @markup.quote

(pipe_table_row
  "|" @punctuation.special)
(pipe_table_header
  "|" @punctuation.special)
(pipe_table_delimiter_row) @punctuation.special

; Canvas protocol (the gi Canvas style). Kept at the end: for one node the
; last matching pattern wins in helix 25.07, so an indented `AA:` entry, which
; markdown parses as an indented code block, takes this scope instead of
; `markup.raw.block`.
((paragraph) @markup.canvas.agent
  (#match? @markup.canvas.agent "^\\s*AA:"))
((indented_code_block) @markup.canvas.agent
  (#match? @markup.canvas.agent "^\\s*AA:"))

; Open markers: `??`/`???`, `!!`/`!!!`, `%%`/`%%%` start their line.
((paragraph) @markup.canvas.marker
  (#match? @markup.canvas.marker "^\\s*(\\?\\?|!!|%%)"))
((indented_code_block) @markup.canvas.marker
  (#match? @markup.canvas.marker "^\\s*(\\?\\?|!!|%%)"))

; Turn headings of an imported canvas: whose turn it is.
((atx_heading (inline) @_text) @markup.heading.user
  (#match? @_text "^\\s*User\\s*$"))
((atx_heading (inline) @_text) @markup.heading.assistant
  (#match? @_text "^\\s*Assistant\\s*$"))
