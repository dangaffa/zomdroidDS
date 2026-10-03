-- Die Surviving: the player's inventory and loot windows live on the bottom screen.
--
-- The game canvas is the top screen (world) on the left plus the bottom screen to its right.
-- DieSurviving_worldWidth() (Java side) says where the world region ends; everything right of it
-- is the bottom screen. The two windows split that strip and stay open: the vanilla mouse mode
-- collapses them to a title bar that expands on hover, which a touch screen can't do.

require "ISUI/PlayerData/ISPlayerDataObject"

if not DieSurviving_worldWidth then return end

local function bottomStrip()
    local canvasW = getCore():getScreenWidth()
    local worldW = DieSurviving_worldWidth(canvasW)
    if not worldW or worldW <= 0 or worldW >= canvasW then return nil end
    return worldW, canvasW - worldW, getCore():getScreenHeight()
end

local original_placeInventoryScreens = ISPlayerDataObject.placeInventoryScreens
function ISPlayerDataObject:placeInventoryScreens(playerID, totalPlayers, mouse)
    original_placeInventoryScreens(self, playerID, totalPlayers, mouse)
    if playerID ~= 0 or totalPlayers > 1 then return end
    local x, w, h = bottomStrip()
    if not x then return end
    local half = math.floor(w / 2)
    self.x1, self.y1, self.w1, self.h1 = x, 0, half, h
    self.x2, self.y2, self.w2, self.h2 = x + half, 0, w - half, h
end

local original_createInventoryInterface = ISPlayerDataObject.createInventoryInterface
function ISPlayerDataObject:createInventoryInterface()
    original_createInventoryInterface(self)
    if self.id ~= 0 or getNumActivePlayers() > 1 or not bottomStrip() then return end
    for _, page in ipairs({ self.playerInventory, self.lootInventory }) do
        page.isCollapsed = false
        page:clearMaxDrawHeight()
        page:setPinned()
    end
end
