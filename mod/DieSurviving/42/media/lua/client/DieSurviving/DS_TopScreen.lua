-- Die Surviving: HUD pieces the game anchors to the canvas's right edge that belong on the top
-- screen, next to the world: the moodles (hunger, pain, panic, ...).
--
-- UIManager.resize re-anchors them every frame, so this runs every frame after it.

require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Vanilla leaves room for the clock above the moodles; the clock is on the bottom screen now.
local MOODLE_TOP = 24
local EDGE = 10

local function onPreUIDraw()
    if not DS.active(0) then return end
    local worldRight = DS.strip()
    local moodles = UIManager.getMoodleUI(0)
    if moodles then
        moodles:setX(worldRight - EDGE - moodles:getWidth())
        moodles:setY(MOODLE_TOP)
    end
end

Events.OnPreUIDraw.Add(onPreUIDraw)
