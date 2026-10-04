-- Die Surviving: the HUD icon column (hands, inventory, health, crafting, map, ...) becomes rows in
-- the bottom screen's HUD band (bottom edge by default; see DS_Layout), left of the clock and speed
-- controls, where the thumbs already are for the menus it opens.

require "ISUI/ISEquippedItem"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

local function fakeBounds(x, y, w, h)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getWidth = function() return w end,
        getHeight = function() return h end,
    }
end

local function layoutAsRows(self)
    local _, _, stripW = DS.strip()
    local cornerW, cornerH = DS.cornerColumn()
    local maxW = stripW - 2 * DS.MARGIN - (cornerW > 0 and cornerW + DS.MARGIN or 0)
    self.dsCornerW, self.dsCornerH = cornerW, cornerH

    -- Row items in their original top-to-bottom order. The movables tooltip is a child too, but it
    -- is a popup, not an icon.
    local items = {}
    for _, child in pairs(self:getChildren()) do
        if child:isVisible() and child.Type ~= "ISMoveablesIconToolTip" then table.insert(items, child) end
    end
    table.sort(items, function(a, b) return a:getY() < b:getY() end)

    local rowH = 0
    for _, child in ipairs(items) do rowH = math.max(rowH, child:getHeight()) end

    -- Left to right, wrapping onto another row when the next icon would not fit.
    local x, y, widest = 0, 0, 0
    for _, child in ipairs(items) do
        if x > 0 and x + child:getWidth() > maxW then
            x = 0
            y = y + rowH + DS.MARGIN
        end
        child:setX(x)
        child:setY(y + math.floor((rowH - child:getHeight()) / 2))
        x = x + child:getWidth() + DS.MARGIN
        widest = math.max(widest, x - DS.MARGIN)
    end
    self:setWidth(widest)
    self:setHeight(y + rowH)
    self:setX(0) -- see setX/setY below
    self:setY(0)
    -- The window area is what the HUD band leaves; move the inventory pages with it.
    DS.hudBlockHeight = self:getHeight()
    if DS.placeInventoryPages then DS.placeInventoryPages() end

    -- The health button wobbles when hurt by having its x reset every frame; remember its slot.
    self.dsHealthX = self.healthBtn and self.healthBtn:getX() or 0

    -- The movables popup opens next to its button; put it above or below the button instead.
    for _, child in pairs(self:getChildren()) do
        if child.Type == "ISMoveablesIconToolTip" and self.movableBtn then
            child:setX(self.movableBtn:getX())
            child:setY(DS.HUD_AT_BOTTOM and self.movableBtn:getY() - child:getHeight() or self.movableBtn:getBottom())
        end
    end

    -- The hand slots' tooltip hit areas are fixed rectangles added first, main hand then off hand.
    local list = self.mouseOverList
    if list then
        for i, hand in ipairs({ self.mainHand, self.offHand }) do
            if list[i] and not list[i].object.Type then
                list[i].object = fakeBounds(hand:getX(), hand:getY(), hand:getWidth(), hand:getHeight())
            end
        end
    end
end

local original_initialise = ISEquippedItem.initialise
function ISEquippedItem:initialise()
    original_initialise(self)
    if self.chr and DS.active(self.chr:getPlayerNum()) then
        self.dsRow = true
        layoutAsRows(self)
    end
end

-- ISPlayerDataObject positions the sidebar at the top-left of the player's screen after creating
-- it (and on resolution changes). In row mode it always sits in the HUD band.
function ISEquippedItem:setX(x)
    if self.dsRow then x = DS.strip() + DS.MARGIN end
    ISUIElement.setX(self, x)
end

function ISEquippedItem:setY(y)
    if self.dsRow then y = DS.hudBlockY(self:getHeight()) end
    ISUIElement.setY(self, y)
end

-- The clock and speed controls can appear (or change size) after the HUD is built.
local original_prerender = ISEquippedItem.prerender
function ISEquippedItem:prerender()
    original_prerender(self)
    if self.dsRow then
        local w, h = DS.cornerColumn()
        if w ~= self.dsCornerW or h ~= self.dsCornerH then layoutAsRows(self) end
    end
end

-- The game puts the clock and speed controls back in the canvas's top-right corner every frame.
Events.OnPreUIDraw.Add(function()
    if DS.active(0) then DS.placeCornerColumn() end
end)

local original_render = ISEquippedItem.render
function ISEquippedItem:render()
    original_render(self)
    if self.dsRow and self.healthBtn then
        -- original_render just set the wobble offset relative to 0; shift it into its slot.
        self.healthBtn:setX(self.dsHealthX + self.healthBtn:getX())
    end
end
