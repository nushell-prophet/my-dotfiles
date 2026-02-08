-- Complete init.lua
-- This file implements two sets of functionality:
-- 1. Keyboard layout switching using left/right ⌘ keys.
-- 2. Hyper mode for fast application launching.

-- Specify your exact layout names (use hs.keycodes.currentLayout() to verify)
-- Debug toggle: set DEBUG = true to enable console logging
local DEBUG = false
local function log(msg)
  if DEBUG then hs.printf("%s", msg) end
end

-------------------------------------
-- Keyboard Layout Switching Section
-------------------------------------

-- Specify your exact layout names (use hs.keycodes.currentLayout() to verify)
local englishLayout = "ABC"
local russianLayout = "Russian – PC"  -- Note: This uses a Unicode en dash!

-- State tracking variables for Command keys.
local leftCmdDown = false
local rightCmdDown = false
local ignoreCmd = false

-- Function to change layout if different from current.
local function setLayout(targetLayout)
  local current = hs.keycodes.currentLayout()
  if current ~= targetLayout then
    log("Switching layout: current = " .. current .. ", target = " .. targetLayout)
    local success = hs.keycodes.setLayout(targetLayout)
    log("Switch success: " .. tostring(success))
  else
    log("Layout already set to: " .. current)
  end
end

-- Eventtap to monitor modifier (flagsChanged) events.
flagsWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(evt)
  local flags = evt:getFlags()
  local code = evt:getKeyCode()
  if code ~= 0x36 and code ~= 0x37 then return false end
  local isCmd = flags.cmd
  
  if not isCmd then
    -- When Command keys are released, if one was pressed alone, change layout.
    if leftCmdDown and not ignoreCmd then
      log("Left Cmd released alone → scheduling switch to English")
      hs.timer.doAfter(0.001, function() setLayout(englishLayout) end)
    elseif rightCmdDown and not ignoreCmd then
      log("Right Cmd released alone → scheduling switch to Russian")
      hs.timer.doAfter(0.001, function() setLayout(russianLayout) end)
    end
    -- Reset all state
    leftCmdDown = false
    rightCmdDown = false
    ignoreCmd = false
  else
    -- When Command is pressed, update state based on keyCode.
    if code == 0x37 then
      leftCmdDown = true
      -- Switch to English immediately on press so Cmd+key shortcuts use English keycodes;
      -- the release handler (line 49) also switches but is a no-op thanks to setLayout guard
      log("Left Cmd pressed → switching to English immediately")
      setLayout(englishLayout)
    elseif code == 0x36 then
      rightCmdDown = true
    end
  end
  
  log("Flags event: cmd=" .. tostring(isCmd) ..
        " leftCmdDown=" .. tostring(leftCmdDown) ..
        " rightCmdDown=" .. tostring(rightCmdDown) ..
        " ignoreCmd=" .. tostring(ignoreCmd))
  return false
end)
flagsWatcher:start()

-- Eventtap to catch any key press (non-Command) when Command is down.
keyDownWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(evt)
  local keyCode = evt:getKeyCode()
  local flags = evt:getFlags()

  -- Cancel layout switch if any key is pressed while Cmd is held
  if leftCmdDown or rightCmdDown then
    ignoreCmd = true
    log("KeyDown event: Non-Command key detected, cancelling layout switch")
  end

  -- ESC without modifiers → switch to English
  if keyCode == 53 and not (flags.cmd or flags.alt or flags.ctrl or flags.shift) then
    log("ESC pressed → switching to English layout")
    hs.timer.doAfter(0.001, function() setLayout(englishLayout) end)
  end

  -- Ctrl + Shift + Space → switch to English
  if keyCode == 49 and flags.ctrl and flags.shift and not flags.cmd and not flags.alt then
    log("Ctrl + Shift + Space pressed → switching to English layout")
    hs.timer.doAfter(0.001, function() setLayout(englishLayout) end)
  end

  -- Replace № with #
  local char = evt:getCharacters()
  if char == "№" then
    hs.eventtap.keyStrokes("#")
    return true
  end

  return false
end)
keyDownWatcher:start()

log("Initial layout: " .. hs.keycodes.currentLayout())

-- Bit masks for remapped modifier key and hyper key modifiers
local flagMasks = hs.eventtap.event.rawFlagMasks
-- Use right ⌘ both as a standalone‑layout switch *and* as the Hyper trigger
local originalKeyMask = flagMasks["deviceRightCommand"] -- right command
local hyperKeyMask = flagMasks["control"] | flagMasks["alternate"] | flagMasks["command"] | flagMasks["shift"]

local hyperMods = { "cmd", "alt", "ctrl", "shift" }
-- Application shortcuts (bundle IDs for maximum speed)
local shortcuts = {
  f = 'com.apple.finder',
  s = 'com.apple.Safari',
  -- t = 'com.apple.Terminal',
  w = 'com.github.wez.wezterm',
  c = 'com.openai.chat'
}

for key, bundleID in pairs(shortcuts) do
  hs.hotkey.bind(hyperMods, key, function()
    hs.application.launchOrFocusByBundleID(bundleID)
  end)
end

------------------------------------------------------------------
-- Cursor navigation with Right‑Option (remapped to hyper) + HJKL
------------------------------------------------------------------
local navKeys = { h = 'left', j = 'down', k = 'up', l = 'right' }

for key, arrow in pairs(navKeys) do
  -- normal press: one arrow key stroke
  -- press‑and‑hold repeats automatically via the third argument
  hs.hotkey.bind(hyperMods, key,
    function() hs.eventtap.keyStroke({}, arrow, 0) end,
    nil,
    function() hs.eventtap.keyStroke({}, arrow, 0) end)
end

-- Build a set of keycodes that have hyper bindings
local hyperBoundKeys = {}
for key, _ in pairs(shortcuts) do
  local code = hs.keycodes.map[key]
  if code then hyperBoundKeys[code] = true end
end
for key, _ in pairs(navKeys) do
  local code = hs.keycodes.map[key]
  if code then hyperBoundKeys[code] = true end
end

-- Remap right_cmd to hyper only for keys with hyper bindings
local events = { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }
KeyEventListener = hs.eventtap.new(events, function(event)
  -- Strip non-coalesced event marker (bit 29) and device-dependent bit (bit 8)
  -- that macOS injects into rawFlags but aren't real modifier state
  local flags = event:rawFlags() & 0xdffffeff
  if flags & originalKeyMask ~= 0 then
    local otherMods = flagMasks["alternate"] | flagMasks["control"] | flagMasks["shift"]
    if (flags & otherMods) == 0 and hyperBoundKeys[event:getKeyCode()] then
      event:rawFlags(hyperKeyMask)
    end
  end
  return false
end):start()

