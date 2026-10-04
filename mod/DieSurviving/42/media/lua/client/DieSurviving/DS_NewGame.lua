-- Die Surviving: fit the Solo "New Game" screen (NewGameScreen) into the bottom screen.
--
-- Its six difficulty cards share the screen width, so on the bottom screen each is narrow and its
-- description wraps far past the card. Two changes:
--  * the small-screen layout (smaller fonts and textures) is always used: the bottom screen is
--    narrower than vanilla's small-screen threshold, but vanilla measures the whole canvas;
--  * the preview area above the cards (a video slot) is capped lower, giving the cards its height.
--
-- Not done by wrapping vanilla's onResolutionChange in a world scope inside pcall: the preview
-- video it creates (getVideo, via updatePreview) came back nil there, and the renderer stalled
-- ~15 s later (Vulkan ran out of swapchain images on the top screen).

require "OptionScreens/NewGameScreen"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Same value as the local at the top of NewGameScreen.lua.
local UI_BORDER_SPACING = 10
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

    -- Vanilla's body with the size flags pinned to the small layout.
    self.smallResolution = true
    self.mediumResolution = true

    self.titleLabel.font = UIFont.NewSmall
    self.titleLabel:setWidthToName()
    self.titleLabel:setX(self.width / 2 - self.titleLabel.width / 2)

    self:calcViewDimensions()
    self.richText:setX(self.viewDimensions.x)
    self.richText:setY(self.viewDimensions.y)
    self.richText:setWidth(self.width - (UI_BORDER_SPACING * 2))
    self.richText:setHeight(self.viewDimensions.previewHeight)
    self:calcViewDimensions()
    self:updatePreview()

    local marginUnderVideo = 6
    for i, panel in ipairs(self.panels) do
        panel:setX(UI_BORDER_SPACING + (i - 1) * (self.viewDimensions.panelWidth + UI_BORDER_SPACING))
        panel:setY(self.viewDimensions.y + self.viewDimensions.previewHeight + UI_BORDER_SPACING + marginUnderVideo)
        panel:setWidth(self.viewDimensions.panelWidth)
        panel:setHeight(self.backButton:getY() - panel:getY() - UI_BORDER_SPACING)
        panel:updateView()
    end
end
