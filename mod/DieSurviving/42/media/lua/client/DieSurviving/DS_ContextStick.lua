-- Die Surviving: the left stick navigates context menus like the d-pad does.
--
-- With a gamepad, a context menu (Y on something in the world) gets the player's joypad focus and
-- is driven by d-pad presses (ISContextMenu:onJoypadDirUp/Down/Left/Right). The left stick only
-- moves the character, and is ignored while a menu has focus. Here it is turned into the same
-- direction steps: one when pushed, then repeating while held, like a held key. Submenus get
-- focus when entered, so they follow automatically. While a menu has focus the character's stick
-- movement is switched off (setIgnoreInputsForDirection), or it would walk away while browsing.

require "ISUI/ISContextMenu"

local THRESHOLD = 0.6       -- stick deflection that counts as a push
local FIRST_REPEAT_MS = 300 -- held: first repeat after this long
local REPEAT_MS = 120       -- then every this long

local held = {} -- per joypad: { dir = "Up"|..., nextMs = time of next repeat }
local frozen = {} -- player numbers whose movement this script switched off

local function isContextMenu(element)
    local mt = getmetatable(element)
    while mt do
        if mt == ISContextMenu then return true end
        mt = getmetatable(mt)
    end
    return false
end

local function stickDirection(joypadId)
    local x = getJoypadMovementAxisX(joypadId)
    local y = getJoypadMovementAxisY(joypadId)
    if math.abs(x) < THRESHOLD and math.abs(y) < THRESHOLD then return nil end
    if math.abs(y) >= math.abs(x) then
        return y < 0 and "Up" or "Down"
    end
    return x < 0 and "Left" or "Right"
end

local function onPreUIDraw()
    local now = getTimestampMs()
    for _, joypadData in pairs(JoypadState.players) do
        local focus = joypadData and joypadData.focus
        local id = joypadData and joypadData.id
        local player = joypadData and joypadData.player
        local inMenu = focus ~= nil and focus:isVisible() and isContextMenu(focus)
        if player ~= nil then
            if inMenu and not frozen[player] then
                setIgnoreInputsForDirection(player, true)
                frozen[player] = true
            elseif not inMenu and frozen[player] then
                setIgnoreInputsForDirection(player, false)
                frozen[player] = nil
            end
        end
        if id ~= nil then
            local dir = inMenu and stickDirection(id) or nil
            local state = held[id]
            if not dir then
                held[id] = nil
            elseif not state or state.dir ~= dir then
                held[id] = { dir = dir, nextMs = now + FIRST_REPEAT_MS }
                focus["onJoypadDir" .. dir](focus, joypadData)
            elseif now >= state.nextMs then
                state.nextMs = now + REPEAT_MS
                focus["onJoypadDir" .. dir](focus, joypadData)
            end
        end
    end
end

Events.OnPreUIDraw.Add(onPreUIDraw)
