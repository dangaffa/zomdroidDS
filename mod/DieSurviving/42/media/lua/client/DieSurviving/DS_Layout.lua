-- Die Surviving: bottom-screen geometry shared by the other DieSurviving scripts.
--
-- The game canvas is the top screen (world) on the left and the bottom screen to its right.
-- DieSurviving_worldWidth() (Java side) says where the world region ends.

DieSurviving = DieSurviving or {}
local DS = DieSurviving

DS.MARGIN = 6

--- Height of one HUD icon row (DS_HUD): the hand slots are the tallest items, TEXTURE_WIDTH square.
--- Same size table as ISEquippedItem's setTextureWidth(), which is local to that file.
function DS.hudRowHeight()
    local size = getCore():getOptionSidebarSize()
    if size == 6 then size = getCore():getOptionFontSizeReal() - 1 end
    local sizes = { [2] = 64, [3] = 80, [4] = 96, [5] = 128 }
    return sizes[size] or 48
end

--- The clock with the game speed controls under it, which the game keeps in the canvas's top-right
--- corner (the bottom screen's). Returns their column's width and bottom edge, or 0, 0.
function DS.cornerColumn()
    local width, bottom = 0, 0
    for _, element in ipairs({ UIManager.getClock(), UIManager.getSpeedControls() }) do
        if element and element:isVisible() then
            width = math.max(width, element:getWidth())
            bottom = math.max(bottom, element:getY() + element:getHeight())
        end
    end
    return width, bottom
end

--- Bottom edge of the HUD rows, set by DS_HUD once laid out.
DS.hudRowsBottom = nil

--- Canvas y where the window area starts: below the HUD rows and the corner column.
function DS.hudBottom()
    local rows = DS.hudRowsBottom or (DS.MARGIN + DS.hudRowHeight())
    local _, cornerBottom = DS.cornerColumn()
    return math.max(rows, cornerBottom) + DS.MARGIN
end

--- x, y, width, height of the whole bottom screen in canvas pixels, or nil on a single screen.
function DS.strip()
    if not DieSurviving_worldWidth then return nil end
    local canvasW = getCore():getScreenWidth()
    local worldW = DieSurviving_worldWidth(canvasW)
    if not worldW or worldW <= 0 or worldW >= canvasW then return nil end
    return worldW, 0, canvasW - worldW, getCore():getScreenHeight()
end

--- The part of the bottom screen windows may use: below the HUD row.
function DS.windowArea()
    local x, y, w, h = DS.strip()
    if not x then return nil end
    local top = DS.hudBottom()
    return x, top, w, h - top
end

--- True on a single local player with a bottom screen. Split-screen co-op keeps vanilla layout.
function DS.active(playerNum)
    if playerNum and playerNum ~= 0 then return false end
    if getNumActivePlayers and getNumActivePlayers() > 1 then return false end
    return DS.strip() ~= nil
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
    local fits = w <= aw
    window:setX(fits and ax + math.floor((aw - w) / 2) or ax + aw - w)
    window:setY(ay + math.max(0, math.floor((ah - h) / 2)))
    return fits
end
