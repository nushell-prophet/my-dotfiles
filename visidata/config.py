options.motd_url = ''

# Swap clipboard cases: lowercase = system clipboard (frequent, no shift), uppercase = internal
Sheet.bindkey('zy', 'syscopy-cell')
Sheet.bindkey('zY', 'copy-cell')
Sheet.bindkey('zp', 'syspaste-cells')
Sheet.bindkey('zP', 'paste-cell')
