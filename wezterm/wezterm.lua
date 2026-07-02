local wezterm = require 'wezterm'

-- ============================================================================
-- LOCAL SETTINGS IMPORT (optional)
-- ============================================================================
local ok, local_settings = pcall(require, 'local_settings')
if not ok then
  local_settings = {}
  wezterm.log_info("No local_settings.lua found, using defaults")
end

-- ============================================================================
-- CONFIGURATION CONSTANTS
-- ============================================================================
local DEFAULTS = {
  font_size = 17.0,
  zen_font_size = 30,
  initial_cols = 220,
  initial_rows = 220,
  max_fps = 255,
  -- Why: deep navy distinguishes the host terminal at a glance from sandbox
  -- sessions, which set a black background via `wezterm-cozy --background`.
  background = '#0a0e27',
}

for k, v in pairs(DEFAULTS) do
  if local_settings[k] == nil then
    local_settings[k] = v
  end
end

-- Initialize configuration
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ============================================================================
-- STARTUP & SHELL
-- ============================================================================
-- Helper function to find executable using system PATH and common locations
local function find_executable(cmd)
  -- Try system PATH first
  local handle = io.popen('which ' .. cmd .. ' 2>/dev/null')
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" then return result end
  end

  -- Get user home directory dynamically
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

  local paths = {}
  if home ~= "" then
    paths = {
      home .. "/.cargo/bin/",
      home .. "/.local/bin/",
      home .. "/bin/",
    }
  end

  -- Append system paths
  for _, p in ipairs({
    "/opt/homebrew/bin/",
    "/usr/local/bin/",
    "/usr/bin/",
    "/bin/",
  }) do
    table.insert(paths, p)
  end

  for _, path in ipairs(paths) do
    local full_path = path .. cmd
    local file = io.open(full_path, "r")
    if file then
      file:close()
      return full_path
    end
  end
end

-- Store nu_path globally for use in keybindings
local nu_path = find_executable('nu')

local function setup_shell()
  if not nu_path then
    wezterm.log_info("Nushell not found, using system default shell")
    return
  end

  local zellij_path = find_executable('zellij')
  config.default_prog = zellij_path
    and { nu_path, '-l', '--execute', 'zellij attach -c prophet' }
    or { nu_path }
end

-- Setup shell
pcall(setup_shell)
config.check_for_updates = false

-- ============================================================================
-- ENVIRONMENT
-- ============================================================================
local function setup_environment()
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
  if home == "" then
    wezterm.log_warn("Unable to determine home directory")
    return {}
  end
  return {
    XDG_CONFIG_HOME = home .. "/.config",
    XDG_DATA_HOME = home .. "/.local/share",
  }
end

-- Setup environment
local ok, env_vars = pcall(setup_environment)
config.set_environment_variables = ok and env_vars or {}

-- ============================================================================
-- APPEARANCE
-- ============================================================================
-- Font configuration with fallback chain
-- WezTerm skips unavailable fonts and uses the next available one
config.font = wezterm.font_with_fallback {
  { family = 'ZedMono Nerd Font', stretch = 'Expanded' }, -- brew install --cask font-zed-mono-nerd-font
  'JetBrains Mono',
  'Fira Code',
  'Cascadia Code',
  'Iosevka',
  'Menlo',
  'Consolas',
  'Courier New',
}
-- Font configuration
-- brew install --cask font-zed-mono-nerd-font
config.font_size = local_settings.font_size

-- Color settings
if local_settings.background then
  config.colors = {
    background = local_settings.background,
  }
end

-- Window settings
config.initial_cols = local_settings.initial_cols
config.initial_rows = local_settings.initial_rows
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

-- Platform-specific settings
local is_macos = wezterm.target_triple:find("darwin") ~= nil
if is_macos then
  config.native_macos_fullscreen_mode = true
end

-- ============================================================================
-- PERFORMANCE
-- ============================================================================
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = local_settings.max_fps
config.animation_fps = local_settings.max_fps

-- ============================================================================
-- BEHAVIOR
-- ============================================================================
config.switch_to_last_active_tab_when_closing_tab = true
config.skip_close_confirmation_for_processes_named = {
  'bash', 'sh', 'zsh', 'fish', 'tmux', 'nu',
}
config.mouse_wheel_scrolls_tabs = false
config.enable_kitty_keyboard = true

-- When set to true (the default), wezterm will configure
-- the SSH_AUTH_SOCK environment variable for panes spawned in
-- the local domain.
config.mux_enable_ssh_agent = false

-- ============================================================================
-- KEY BINDINGS
-- ============================================================================
config.disable_default_key_bindings = true
config.keys = {
  { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
  { key = 'x', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
  { key = 'p', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCommandPalette },
  { key = 'v', mods = 'CMD',        action = wezterm.action.PasteFrom 'Clipboard' },
  { key = '=', mods = 'CMD',        action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD',        action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD',        action = wezterm.action.ResetFontSize },
  { key = 'q', mods = 'CMD',        action = wezterm.action.QuitApplication },

  -- Why: Claude Code doesn't recognize Shift+Enter for newlines without an explicit Kitty-style CSI u sequence
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\x1b[13;2u' },

  -- I use those keybidings here to check that to fix Wezterms cmd+shift passing for zellij.
  -- cmd+shift+a
  { key = 'a', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[97;10u' },
  -- cmd+shift+b
  { key = 'b', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[98;10u' },
  -- cmd+shift+c
  { key = 'c', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[99;10u' },
  -- cmd+shift+d
  { key = 'd', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[100;10u' },
  -- cmd+shift+e
  { key = 'e', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[101;10u' },
  -- cmd+shift+f
  { key = 'f', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[102;10u' },
  -- cmd+shift+g
  { key = 'g', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[103;10u' },
  -- cmd+shift+h
  { key = 'h', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[104;10u' },
  -- cmd+shift+i
  { key = 'i', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[105;10u' },
  -- cmd+shift+j
  { key = 'j', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[106;10u' },
  -- cmd+shift+k
  { key = 'k', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[107;10u' },
  -- cmd+shift+l
  { key = 'l', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[108;10u' },
  -- cmd+shift+m
  { key = 'm', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[109;10u' },
  -- cmd+shift+n (new wezterm instance with its own Dock icon, running pure nushell)
  -- Why: SpawnCommandInNewWindow reuses the same OS process, so the new window
  -- ends up under the existing Dock icon. `open -n` asks LaunchServices for a
  -- fresh app instance (own Dock icon + foreground activation, side-stepping
  -- wezterm issue #6202 where `wezterm start --always-new-process` opens in the
  -- background on macOS).
  -- `--always-new-process` is required: without it, the freshly-launched
  -- wezterm-gui detects the existing mux via its unix socket, delegates the
  -- spawn to the running instance, and exits — collapsing the new window back
  -- under the old Dock icon.
  { key = 'n', mods = 'CMD|SHIFT', action = wezterm.action_callback(function()
    wezterm.background_child_process({ 'open', '-n', '-a', 'WezTerm', '--args', 'start', '--always-new-process', '--', nu_path or 'nu' })
  end)},
  { key = 'n', mods = 'ALT|CMD',   action = wezterm.action_callback(function()
    wezterm.background_child_process({ 'open', '-n', '-a', 'WezTerm', '--args', 'start', '--always-new-process', '--', 'zsh' })
  end)},
  -- cmd+shift+o
  { key = 'o', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[111;10u' },
  -- cmd+shift+p
  { key = 'p', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[112;10u' },
  -- cmd+shift+q
  { key = 'q', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[113;10u' },
  -- cmd+shift+r
  { key = 'r', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[114;10u' },
  -- cmd+shift+s
  { key = 's', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[115;10u' },
  -- cmd+shift+t
  { key = 't', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[116;10u' },
  -- cmd+shift+u
  { key = 'u', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[117;10u' },
  -- cmd+shift+v
  { key = 'v', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[118;10u' },
  -- cmd+shift+w
  { key = 'w', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[119;10u' },
  -- cmd+shift+x
  { key = 'x', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[120;10u' },
  -- cmd+shift+y
  { key = 'y', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[121;10u' },
  -- cmd+shift+z
  { key = 'z', mods = 'CMD|SHIFT',  action = wezterm.action.SendString '\x1b[122;10u' },
}

-- ============================================================================
-- QUICK SELECT PATTERNS
-- ============================================================================
local quick_select_patterns = {
  -- git commit ranges: hash..hash (two-dot) and hash...hash (three-dot),
  -- matched as one block. Must precede the bare-hash/jj rules below so the
  -- whole range wins over selecting a single side.
  "\\b[0-9a-f]{7,64}\\.{2,3}[0-9a-f]{7,64}\\b",

  -- jj change IDs (use k-z alphabet to avoid forming words)
  "\\b[k-z]{8,12}\\b",

  -- file:line:col (rg --vimgrep, nushell table rows, stack traces,
  -- nushell error headers like ╭─[/path/to/file.nu:1946:63])
  "[^\\s│╭─\\[]+:\\d+:\\d+",

  -- Table patterns
  -- $env.config.table.mode = "default"
  -- $env.config.table.header_on_separator = true
  -- $env.config.footer_mode = "Always"
  "(?<=─|╭|┬)([a-zA-Z0-9 _%.-]+?)(?=─|╮|┬)", -- Headers
  "(?<=│ )([a-zA-Z0-9 _.-]+?)(?= │)", -- Column values

  -- File paths (stops at ~; strips trailing punctuation like . , ; : via lookbehind)
  "/[^/\\s│~]+(?:/[^/\\s│~]+)*(?<![.,;:!?)\\]>])",
}

config.quick_select_patterns = quick_select_patterns
config.quick_select_remove_styling = true

-- ============================================================================
-- DYNAMIC CONFIGURATION (ZEN MODE)
-- ============================================================================
-- Demo mode for screencasts. Activate in wezterm (outside of zellij) via:
-- 'on' | encode base64 | $"\e]1337;SetUserVar=ZEN_MODE=($in)\e"
-- 'off' | encode base64 | $"\e]1337;SetUserVar=ZEN_MODE=($in)\e"
wezterm.on('user-var-changed', function(window, pane, name, value)
  local overrides = window:get_config_overrides() or {}
  if name == "ZEN_MODE" then
    overrides.font_size = value == "on" and local_settings.zen_font_size or nil
  end
  window:set_config_overrides(overrides)
end)

return config
