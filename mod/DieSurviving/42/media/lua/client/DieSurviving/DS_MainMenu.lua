-- Die Surviving: main menu layout. The menu list, logo and painting stay on the top screen
-- (driven by the gamepad); every screen the menu opens (Load, Options, Mods, Solo setup, character
-- creation, ...) sits on the bottom screen.
--
-- MainScreen stays as wide as the canvas so it keeps receiving touches on the bottom screen; its
-- sub-screens are children, so they are placed at the bottom strip's offset inside it.

require "OptionScreens/MainScreen"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- MainScreen fields holding its sub-screens (see MainScreen:instantiate).
local SUB_SCREENS = {
    "bootstrapConnectPopup", "connectToServer", "serverConnectPopup", "multiplayer", "soloScreen",
    "loadScreen", "onlineCoopScreen", "workshopSubmit", "serverWorkshopItem", "mainOptions",
    "creditsScreen", "scoreboard", "inviteFriends", "sandOptions", "worldSelect", "mapSpawnSelect",
    "modSelect", "charCreationMain", "charCreationProfession", "lastStandPlayerSelect",
    "serverSettingsScreen",
}

local function placeOnBottom(ui)
    if not ui or not ui.javaObject then return end
    local x, y, w, h = DS.strip()
    -- Size first: setX/setY keep an element on screen using its current size.
    ui:setWidth(w)
    ui:setHeight(h)
    ui:setX(x)
    ui:setY(y)
    if ui.recalcSize then ui:recalcSize() end
end

local function layout(self)
    if not DS.active(0) then return end
    for _, name in ipairs(SUB_SCREENS) do
        placeOnBottom(self[name])
    end
    if self.versionBtn then
        local worldW = DS.strip()
        self.versionBtn:setX(worldW / 2 - self.versionBtn:getWidth() / 2)
    end
end

local original_instantiate = MainScreen.instantiate
function MainScreen:instantiate()
    original_instantiate(self)
    layout(self)
end

-- The logo is scaled and placed from getCore():getScreenWidth(); draw it as if the screen were the
-- top screen. (Don't call DS.strip() inside the scope: it reads the screen width too.)
local original_prerender = MainScreen.prerender
function MainScreen:prerender()
    if not DS.active(0) or self.inGame then return original_prerender(self) end
    -- The painting can overhang the top screen; the bottom screen behind the menu is plain black.
    local x, y, w, h = DS.strip()
    DieSurviving_enterWorldScope()
    local ok, err = pcall(original_prerender, self)
    DieSurviving_exitWorldScope()
    if not ok then error(err) end
    self:drawRect(x, y, w, h, 1, 0, 0, 0)
end

-- The debug-only scenario list is created later, centred on the canvas.
local original_doDebugScenarios = doDebugScenarios
if original_doDebugScenarios then
    function doDebugScenarios(...)
        original_doDebugScenarios(...)
        if DS.active(0) and DebugScenarios and DebugScenarios.instance then
            local x, y, w, h = DS.strip()
            local panel = DebugScenarios.instance
            panel:setX(x + math.max(0, (w - panel:getWidth()) / 2))
        end
    end
end
