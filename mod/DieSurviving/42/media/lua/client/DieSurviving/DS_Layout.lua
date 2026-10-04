-- Die Surviving: bottom-screen geometry shared by the other DieSurviving scripts.
--
-- The game canvas is the top screen (world) on the left and the bottom screen to its right.
-- DieSurviving_worldWidth() (Java side) says where the world region ends.
--
-- The bottom screen has a HUD band along one edge (the bottom by default, near the thumbs): the
-- HUD icon rows (DS_HUD) on the left and the clock with the game speed controls under it in the
-- corner. Windows use the rest (the window area).

DieSurviving = DieSurviving or {}
local DS = DieSurviving

DS.MARGIN = 6

-- Which edge of the bottom screen the HUD band sits on. Bottom is easier to reach than the edge
-- next to the hinge. TODO: make this a mod option.
DS.HUD_AT_BOTTOM = true

-- Height of the HUD icon block, set by DS_HUD once laid out.
DS.hudBlockHeight = nil

--- x, y, width, height of the whole bottom screen in canvas pixels, or nil on a single screen.
function DS.strip()
    if not DieSurviving_worldWidth then return nil end
    local canvasW = getCore():getScreenWidth()
    local worldW = DieSurviving_worldWidth(canvasW)
    if not worldW or worldW <= 0 or worldW >= canvasW then return nil end
    return worldW, 0, canvasW - worldW, getCore():getScreenHeight()
end

--- True on a single local player with a bottom screen. Split-screen co-op keeps vanilla layout.
function DS.active(playerNum)
    if playerNum and playerNum ~= 0 then return false end
    if getNumActivePlayers and getNumActivePlayers() > 1 then return false end
    return DS.strip() ~= nil
end

--- Height of one HUD icon row: the hand slots are the tallest items, TEXTURE_WIDTH square.
--- Same size table as ISEquippedItem's setTextureWidth(), which is local to that file.
function DS.hudRowHeight()
    local size = getCore():getOptionSidebarSize()
    if size == 6 then size = getCore():getOptionFontSizeReal() - 1 end
    local sizes = { [2] = 64, [3] = 80, [4] = 96, [5] = 128 }
    return sizes[size] or 48
end

local GAP = 4

local function cornerElements()
    local list = {}
    for _, element in ipairs({ UIManager.getClock(), UIManager.getSpeedControls() }) do
        if element and element:isVisible() then table.insert(list, element) end
    end
    return list
end

--- Width and height of the corner column: the clock with the speed controls under it.
function DS.cornerColumn()
    local width, height = 0, 0
    for i, element in ipairs(cornerElements()) do
        width = math.max(width, element:getWidth())
        height = height + element:getHeight() + (i > 1 and GAP or 0)
    end
    return width, height
end

--- y of a block of the given height inside the HUD band.
local function bandY(height)
    local _, sy, _, sh = DS.strip()
    if DS.HUD_AT_BOTTOM then return sy + sh - DS.MARGIN - height end
    return sy + DS.MARGIN
end

--- Put the clock and speed controls in the HUD band's right corner. The game re-anchors them to
--- the canvas's top-right corner every frame (UIManager.resize), so this runs every frame after it.
function DS.placeCornerColumn()
    local sx, _, sw = DS.strip()
    if not sx then return end
    local _, colH = DS.cornerColumn()
    local y = bandY(colH)
    for _, element in ipairs(cornerElements()) do
        element:setX(sx + sw - DS.MARGIN - element:getWidth())
        element:setY(y)
        y = y + element:getHeight() + GAP
    end
end

--- y for the HUD icon block of the given height.
function DS.hudBlockY(height)
    return bandY(height)
end

--- The part of the bottom screen windows may use: everything but the HUD band.
function DS.windowArea()
    local x, y, w, h = DS.strip()
    if not x then return nil end
    local _, colH = DS.cornerColumn()
    local band = math.max(DS.hudBlockHeight or DS.hudRowHeight(), colH) + 2 * DS.MARGIN
    if DS.HUD_AT_BOTTOM then return x, y, w, h - band end
    return x, y + band, w, h - band
end

--- Fit a top-level window into the bottom screen's window area, shrinking it if it allows.
--- A window still wider than the area is right-aligned to the canvas edge, which keeps as much of
--- it on the bottom screen as possible (the game clamps windows to the canvas anyway).
--- Returns false if it doesn't fit.
function DS.placeInWindowArea(window)
    local ax, ay, aw, ah = DS.windowArea()
    if not ax then return true end
    local w, h = window:getWidth(), window:getHeight()
    if w > aw and window.resizable ~= false then
        window:setWidth(aw)
        w = window:getWidth()
    end
    if h > ah and window.resizable ~= false then
        window:setHeight(ah)
        h = window:getHeight()
    end
    -- Size first: setX/setY keep a window on screen using its current size.
    local fits = w <= aw
    window:setX(fits and ax + math.floor((aw - w) / 2) or ax + aw - w)
    window:setY(ay + math.max(0, math.floor((ah - h) / 2)))
    return fits
end
