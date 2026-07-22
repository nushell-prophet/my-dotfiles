# Baseline of variable names to exclude from the Alt+O vars menu (consumed in `nushell/config.nu`, `vars-menu-source`).
# `zzz_` prefix so this runs last in autoload — the snapshot then includes vars added by every module.
$env.ignore-env-vars = (scope variables | get name)
