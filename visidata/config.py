options.motd_url = ''
options.clipboard_copy_cmd = 'pbcopy'
# Why: an accidental q closed a sheet with work in it; ask before quitting a modified sheet.
options.quitguard = True

# Why: one lowercase zy feeds BOTH clipboards — internal (vd.memory.clipval,
# which zp pastes from) and system (pbcopy). Internal copy runs first so zp
# stays functional even if the system copy ever fails.
Sheet.addCommand(
    'zy', 'copy-cell-syscopy',
    'copyCells(cursorCol, [cursorRow]); vd.memoValue("clipval", cursorTypedValue, cursorDisplay); syscopyValue(cursorDisplay)',
    'yank current cell to both internal and system clipboard',
)

# Why: reading long cells one record at a time — Enter opens a row as a record
# sheet, and from there Alt+j and Alt+k step to the next and previous row of the
# parent without q, j, Enter. The record sheet does not know its parent, so this
# takes the sheet directly under it and checks that this sheet shows its cursor row.
@Sheet.api
def open_sibling_row(sheet, n):
    'close this record sheet, move the parent cursor by n rows, open that row on the same field'
    parent = vd.sheets[1] if len(vd.sheets) > 1 else None
    # Why: Enter on a JSON row gives a SheetDict whose source is the row; on a CSV row
    # (in-vd sends flat tables as CSV) a TableSheet with sourceRow. A dict opened from
    # a cell with zEnter matches neither, so it is not closed.
    shown = sheet.source if isinstance(sheet, SheetDict) else getattr(sheet, 'sourceRow', None)
    if parent is None or shown is None or shown is not parent.cursorRow:
        vd.fail('not a record sheet opened with Enter')
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

# Not [ and ] because: they sort, and a record sheet of a CSV row is a plain TableSheet.
# Not Alt+[ because: ESC [ starts the escape code of arrows and other keys.
Sheet.addCommand('Alt+j', 'open-next-row', 'open_sibling_row(1)', 'close record sheet, open next row of parent')
Sheet.addCommand('Alt+k', 'open-prev-row', 'open_sibling_row(-1)', 'close record sheet, open previous row of parent')
