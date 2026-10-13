---
status: in_progress #draft | in_progress | completed | rejected
agents-mode: co-editing #read-only | grammar-fixes | co-editing
updated: '20261013' #yyyyMMdd
session: 4228d8b5-ea25-457b-a68f-44c7f7fe4130
---

# wezterm-to-not-select-leading-ab-from-diff-paths

Make wezterm *not select* *the* leading a/ b/ from *diff* paths

    AA: Quick select (`ctrl+shift+space`) now gives `x/y.lua` for `a/x/y.lua` and `b/x/y.lua` in diff output — `ntwnouvs`.
    A real directory named `a` or `b` loses that first segment too.
    Not tested in a live wezterm: it runs on the host; to load it, push `wezterm/wezterm.lua` with the host profile.

    ??? I read "select" as quick select. Double-click selection cannot drop a prefix: wezterm only lets you set the boundary characters, and adding `/` would split every path. Default: quick select only.
