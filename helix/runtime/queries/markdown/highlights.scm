
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
; last matching pattern wins in helix 25.07.
; Not `indented_code_block` too: an `AA:` line indented after a blank line is
; one, but the block runs on over blank lines through every deeper indented
; line under it, and helix has no node for one line, so the user's text there
; would take the colour of the entry.
((paragraph) @markup.canvas.agent
  (#match? @markup.canvas.agent "^\\s*AA:"))

; Open markers: `??`/`???`, `!!`/`!!!`, `%%`/`%%%` start their line.
((paragraph) @markup.canvas.marker
  (#match? @markup.canvas.marker "^\\s*(\\?\\?|!!|%%)"))

; Turn headings of an imported canvas: whose turn it is.
((atx_heading (inline) @_text) @markup.heading.user
  (#match? @_text "^\\s*User\\s*$"))
((atx_heading (inline) @_text) @markup.heading.assistant
  (#match? @_text "^\\s*Assistant\\s*$"))
