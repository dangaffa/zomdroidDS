-- Die Surviving: fit the Solo "New Game" screen (NewGameScreen) into the bottom screen.
--
-- Its six difficulty cards share the screen width, so on the bottom screen each is narrow and its
-- description wraps far past the card. Two changes:
--  * the font/texture size flags (smallResolution, from the screen width) are computed against
--    the top screen's width, which selects the small layout;
--  * the preview area above the cards (a video slot) is capped lower, giving the cards its height.

require "OptionScreens/NewGameScreen"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

local PREVIEW_MAX_HEIGHT = 0.3 -- of the screen's height

local original_calcViewDimensions = NewGameScreen.calcViewDimensions
function NewGameScreen:calcViewDimensions()
    original_calcViewDimensions(self)
    if not DS.active(0) then return end
    local v = self.viewDimensions
    local maxHeight = self.height * PREVIEW_MAX_HEIGHT
    if v.previewHeight > maxHeight then
        v.previewWidth = v.previewWidth * maxHeight / v.previewHeight
        v.previewHeight = maxHeight
    end
end

local original_onResolutionChange = NewGameScreen.onResolutionChange
function NewGameScreen:onResolutionChange(...)
    if not DS.active(0) then return original_onResolutionChange(self, ...) end
    DieSurviving_enterWorldScope()
    local ok, err = pcall(original_onResolutionChange, self, ...)
    DieSurviving_exitWorldScope()
    if not ok then error(err) end
end
