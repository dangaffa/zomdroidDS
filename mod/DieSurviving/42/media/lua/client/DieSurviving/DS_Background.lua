-- Die Surviving: a black backdrop behind all UI on the bottom screen.
--
-- Nothing else clears that part of the canvas: the world only clears its own viewport, and the UI
-- only draws where it has elements, so anything drawn once in an empty spot would linger there.
-- It also catches taps on empty parts of the bottom screen, which would otherwise reach the world.

require "ISUI/ISPanel"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

local function createBackdrop()
    if not DS.active(0) then return end
    local x, y, w, h = DS.strip()
    local panel = ISPanel:new(x, y, w, h)
    panel.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    panel.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    panel.moveWithMouse = false
    panel:initialise()
    panel:addToUIManager()
    panel:backMost()
    DS.backdrop = panel
end

local function onResolutionChange()
    if DS.backdrop then
        local x, y, w, h = DS.strip()
        if x then
            DS.backdrop:setWidth(w)
            DS.backdrop:setHeight(h)
            DS.backdrop:setX(x)
            DS.backdrop:setY(y)
        end
    end
end

Events.OnGameStart.Add(createBackdrop)
Events.OnResolutionChange.Add(onResolutionChange)
