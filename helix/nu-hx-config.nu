# Config hx-nu passes to `nu --config`: cozy modules when present, plus the
# Helix helper module (nu-hx.nu, resolved relative to this file).
# Why conditional: modules-core.nu is cozy-owned and absent on a bare-dotfiles
# host without cozy; `source` of a missing file is a hard parser error that
# would kill ALL Helix↔nushell commands. `source null` is a no-op.
const cozy = ("~/.config/nushell/autoload/modules-core.nu" | path expand)
source (if ($cozy | path exists) { $cozy } else { null })
use nu-hx.nu
