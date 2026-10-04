-- Die Surviving: fit character creation into the bottom screen.
--
-- Occupation & traits (CharacterCreationProfession): the bottom row holds Back, the saved-builds
-- combo with Save/Del, then Reset Traits, Random and Next from the right. On the narrow bottom
-- screen the right-hand buttons run into Del, so the combo shrinks to make room.

require "OptionScreens/CharacterCreationProfession"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Same value as the local at the top of CharacterCreationProfession.lua.
local UI_BORDER_SPACING = 10
local MIN_COMBO_WIDTH = 120

local original_create = CharacterCreationProfession.create
function CharacterCreationProfession:create()
    original_create(self)
    if not DS.active(0) then return end
    local panel, combo = self.presetPanel, self.savedBuilds
    if not (panel and combo and self.saveBuildButton and self.deleteBuildButton and self.resetButton) then return end

    local available = self.resetButton:getX() - UI_BORDER_SPACING - panel:getX()
    if panel:getWidth() <= available then return end
    local buttons = self.saveBuildButton:getWidth() + self.deleteBuildButton:getWidth() + UI_BORDER_SPACING * 2
    combo:setWidth(math.max(MIN_COMBO_WIDTH, available - buttons))
    self.saveBuildButton:setX(combo:getRight() + UI_BORDER_SPACING)
    self.deleteBuildButton:setX(self.saveBuildButton:getRight() + UI_BORDER_SPACING)
    panel:setWidth(self.deleteBuildButton:getRight())
end
