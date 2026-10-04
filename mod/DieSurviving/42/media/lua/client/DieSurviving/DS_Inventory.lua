-- Die Surviving: the player's inventory and loot windows live on the bottom screen, side by side
-- below the HUD row. They stay open: the vanilla mouse mode collapses them to a title bar that
-- expands on hover, which a touch screen can't do.

require "ISUI/PlayerData/ISPlayerDataObject"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

local original_placeInventoryScreens = ISPlayerDataObject.placeInventoryScreens
function ISPlayerDataObject:placeInventoryScreens(playerID, totalPlayers, mouse)
    original_placeInventoryScreens(self, playerID, totalPlayers, mouse)
    if totalPlayers > 1 or not DS.active(playerID) then return end
    local x, y, w, h = DS.windowArea()
    local half = math.floor(w / 2)
    self.x1, self.y1, self.w1, self.h1 = x, y, half, h
    self.x2, self.y2, self.w2, self.h2 = x + half, y, w - half, h
end

--- Put player 0's inventory and loot pages side by side in the window area. Called again when the
--- HUD rows change height.
function DS.placeInventoryPages()
    local data = getPlayerData and getPlayerData(0)
    if not data or not data.playerInventory or not DS.active(0) then return end
    local x, y, w, h = DS.windowArea()
    local half = math.floor(w / 2)
    for i, page in ipairs({ data.playerInventory, data.lootInventory }) do
        -- Size first: setX/setY keep a window on screen using its current size.
        page:setWidth(i == 1 and half or w - half)
        page:setHeight(h)
        page:setX(i == 1 and x or x + half)
        page:setY(y)
    end
end

local original_createInventoryInterface = ISPlayerDataObject.createInventoryInterface
function ISPlayerDataObject:createInventoryInterface()
    original_createInventoryInterface(self)
    if not DS.active(self.id) then return end
    for _, page in ipairs({ self.playerInventory, self.lootInventory }) do
        page.isCollapsed = false
        page:clearMaxDrawHeight()
        page:setPinned()
    end
end
