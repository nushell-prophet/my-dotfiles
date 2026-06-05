options.motd_url = ''
options.clipboard_copy_cmd = 'pbcopy'

# Why: one lowercase zy feeds BOTH clipboards — internal (vd.memory.clipval,
# which zp pastes from) and system (pbcopy). Internal copy runs first so zp
# stays functional even if the system copy ever fails.
Sheet.addCommand(
    'zy', 'copy-cell-syscopy',
    'copyCells(cursorCol, [cursorRow]); vd.memoValue("clipval", cursorTypedValue, cursorDisplay); syscopyValue(cursorDisplay)',
    'yank current cell to both internal and system clipboard',
)
