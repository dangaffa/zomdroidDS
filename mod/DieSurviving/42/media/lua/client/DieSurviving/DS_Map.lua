-- Die Surviving: the world map opens on the bottom screen, where it can be panned and marked by
-- touch, and the world stays visible on the top screen.
--
-- Vanilla sizes the map to the whole canvas, re-checking every frame in ISWorldMap:render, and
-- turns world drawing off while it is open because it would be hidden anyway.

require "ISUI/Maps/ISWorldMap"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

local function area()
    if not DS.active(0) then return nil end
    return DS.strip()
end

function ISWorldMap:setX(x)
    local ax = area()
    ISPanelJoypad.setX(self, ax or x)
end

function ISWorldMap:setY(y)
    local _, ay = area()
    ISPanelJoypad.setY(self, ay or y)
end

function ISWorldMap:setWidth(w)
    local _, _, aw = area()
    ISPanelJoypad.setWidth(self, aw or w)
end

function ISWorldMap:setHeight(h)
    local _, _, _, ah = area()
    ISPanelJoypad.setHeight(self, ah or h)
end

local original_addToUIManager = ISWorldMap.addToUIManager or ISUIElement.addToUIManager
function ISWorldMap:addToUIManager()
    local ax, ay, aw, ah = area()
    if ax then
        -- Constructed at 0,0 with the canvas size; size first, setX/setY keep it on screen.
        self:setWidth(aw)
        self:setHeight(ah)
        self:setX(ax)
        self:setY(ay)
    end
    original_addToUIManager(self)
end

local original_render = ISWorldMap.render
function ISWorldMap:render()
    original_render(self)
    if area() then getWorld():setDrawWorld(true) end
end
