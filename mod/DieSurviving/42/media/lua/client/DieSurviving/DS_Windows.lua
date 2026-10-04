-- Die Surviving: windows open on the bottom screen by default.
--
-- Any top-level window or dialog shown in the world area (the top screen) is moved into the bottom
-- screen's window area. Checked every UI frame, because many windows centre themselves on the
-- canvas when they open (SurvivalGuide:restorePosition, for one). Things that belong to the world
-- or to the gamepad stay where the game puts them (see EXCLUDED). A window the player drags onto
-- the top screen stays there.

require "ISUI/ISUIElement"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Never moved: world-anchored, gamepad-driven, or placed by another DieSurviving script.
local EXCLUDED = {
    ISContextMenu = true,          -- world context menus stay on top; inventory ones open under the finger
    ISToolTip = true,
    ISToolTipInv = true,
    ISEquippedItem = true,         -- DS_HUD
    ISInventoryPage = true,        -- DS_Inventory
    ISButtonPrompt = true,
    ISRadialMenu = true,
    ISMoveablesIconPopup = true,
}

-- Classes whose instances count as movable windows or dialogs.
local WINDOW_CLASSES = {
    "ISCollapsableWindow", "ISCollapsableWindowJoypad",
    "ISModalDialog", "ISModalRichText", "ISTextBox",
}

local function derivesFrom(obj, class)
    if not class then return false end
    local mt = getmetatable(obj)
    while mt do
        if mt == class then return true end
        mt = getmetatable(mt)
    end
    return false
end

local function isWindow(element)
    if EXCLUDED[element.Type] then return false end
    for _, name in ipairs(WINDOW_CLASSES) do
        if derivesFrom(element, _G[name]) then return true end
    end
    return false
end

local function inGame()
    return getSpecificPlayer and getSpecificPlayer(0) ~= nil
end

local function update(window, worldRight)
    if not window:isVisible() then
        window.dsPlaced = nil -- re-place next time it opens
        window.dsTooWide = nil
        return
    end
    if window.dsUserPlaced then return end
    if window.moving then
        -- The player is dragging it; wherever it ends up is their choice.
        if window.dsPlaced then window.dsUserPlaced = true end
        return
    end
    if window.dsTooWide then return end
    if window:getX() < worldRight then
        -- Too wide for the bottom screen: place it once, then leave it be, or this would fight
        -- the game's own clamping every frame.
        window.dsTooWide = not DS.placeInWindowArea(window)
    end
    window.dsPlaced = true
end

local function onPreUIDraw()
    if not inGame() or not DS.active(0) then return end
    local worldRight = DS.strip()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local javaObject = ui:get(i)
        local window = javaObject.getTable and javaObject:getTable()
        if window and not window.parent and isWindow(window) then
            update(window, worldRight)
        end
    end
end

Events.OnPreUIDraw.Add(onPreUIDraw)
