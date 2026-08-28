; Continuation lines of a list item line up with the item's content,
; not with a fixed indent unit: "- " gives 2, "1. " gives 3, "10. " gives 4.
; The anchor is the first node after the marker, so its start column is the
; content column whatever the marker looks like.
(list_item
  [
    (list_marker_minus)
    (list_marker_plus)
    (list_marker_star)
    (list_marker_dot)
    (list_marker_parenthesis)
  ]
  .
  (_) @anchor
  (#set! "scope" "tail")) @align
