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

# Why: reading long cells one record at a time — Enter opens a row as a record
# sheet, and from there ] and [ step to the next and previous row of the parent
# without q, j, Enter. The record sheet does not know its parent, so this takes
# the sheet directly under it, which is the parent right after Enter.
@Sheet.api
def open_sibling_row(sheet, n):
    'close this record sheet, move the parent cursor by n rows, open that row on the same field'
    parent = vd.sheets[1]
    field = sheet.cursorRowIndex
    vd.quit(sheet)
    parent.cursorDown(n)
    vs = parent.openRow(parent.cursorRow)
    vd.push(vs)
    vd.sync()  # rows load in a thread; a cursor set before they arrive is lost
    vs.cursorRowIndex = field
    # Why: v (multiline) and column widths are set per column of one sheet, so carry them over
    for old in sheet.columns:
        new = vs.colsByName.get(old.name)
        if new:
            new.height, new.width = old.height, old.width

# Not Ctrl+N/Ctrl+P because: Ctrl+P is status history. Not Alt+j/k: zellij takes them.
# Bound on SheetDict only, so [ and ] keep sorting on every table sheet.
SheetDict.addCommand(']', 'open-next-row', 'open_sibling_row(1)', 'close record sheet, open next row of parent')
SheetDict.addCommand('[', 'open-prev-row', 'open_sibling_row(-1)', 'close record sheet, open previous row of parent')
