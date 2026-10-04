-- Die Surviving: fit the Survival Guide into the bottom screen.
--
-- Vanilla is the topic list plus a fixed 960x480 video area with the description under it, about
-- 1100 px wide. On the bottom screen the window fills the window area: list on the left, the video
-- scaled to the remaining width (same 2:1 shape), the description under it taking the rest.
--
-- Something resizes the window again after it is first laid out, and the anchored children follow
-- that; so the layout is re-applied in prerender whenever it has drifted. The background is made
-- opaque: on the bottom screen other windows sit right behind it.
--
-- The guide's videos don't load on Zomdroid (getVideo returns nil, in vanilla too), which leaves an
-- empty slot half the window tall. When the selected topic's video fails to load, the slot shrinks
-- to the topic title and the description moves up.
--
-- onClickList (which creates the video via the rich text <VIDEOCENTRE> tag) is re-implemented,
-- not wrapped: see the Gotchas in CLAUDE.md about videos created inside wrappers.

require "SurvivalGuide/SurvivalGuide"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Same values as the locals at the top of SurvivalGuide.lua.
local VIDEO_WIDTH = 960
local VIDEO_HEIGHT = 480
local UI_BORDER_SPACING = 2
local BTN_HEIGHT = 25
local BOTTOM_PANEL_HEIGHT = BTN_HEIGHT + UI_BORDER_SPACING * 2

local function active(self)
    return DS.active(0) and self.listBox ~= nil
end

-- Small fonts throughout: populateList picks the list font from this flag.
local original_populateList = SurvivalGuide.populateList
function SurvivalGuide:populateList()
    if DS.active(0) then
        self.smallResolution = true
        self.mediumResolution = true
    end
    return original_populateList(self)
end

local function layout(self)
    local ax, ay, aw, ah = DS.windowArea()
    local th = self:titleBarHeight()
    local listW = self.listBox:getWidth()
    local contentW = aw - listW
    local bodyH = ah - th - BOTTOM_PANEL_HEIGHT

    -- Size first: setX/setY keep a window on screen using its current size.
    self:setWidth(aw)
    self:setHeight(ah)

    self.listBox:setX(0)
    self.listBox:setY(th)
    self.listBox:setHeight(bodyH)

    local titleH = getTextManager():getFontHeight(UIFont.Medium) + 8
    self.dsVideoW = math.floor(contentW)
    self.dsVideoH = math.floor(contentW * VIDEO_HEIGHT / VIDEO_WIDTH)
    local videoPanelH = math.min(bodyH, titleH + (self.dsNoVideo and 0 or self.dsVideoH))

    self.videoRichText:setX(listW)
    self.videoRichText:setY(th)
    self.videoRichText:setWidth(contentW)
    self.videoRichText:setHeight(videoPanelH)

    self.descriptionRichText:setX(listW)
    self.descriptionRichText:setY(th + videoPanelH)
    self.descriptionRichText:setWidth(contentW)
    self.descriptionRichText:setHeight(bodyH - videoPanelH)

    self.showGuideTickBox:setY(ah - BTN_HEIGHT - 2)
    self.closeButton:setX(aw - self.closeButton:getWidth() - UI_BORDER_SPACING)
    self.closeButton:setY(ah - BTN_HEIGHT - 2)

    self:setX(ax)
    self:setY(ay)
    self.dsLayout = { ax, ay, aw, ah, self.dsNoVideo }
end

local function drifted(self)
    local ax, ay, aw, ah = DS.windowArea()
    local l = self.dsLayout
    return not l or l[1] ~= ax or l[2] ~= ay or l[3] ~= aw or l[4] ~= ah
        or self:getWidth() ~= aw or self:getHeight() ~= ah
        or self.closeButton:getY() ~= ah - BTN_HEIGHT - 2
        or l[5] ~= self.dsNoVideo
end

local original_prerender = SurvivalGuide.prerender
function SurvivalGuide:prerender()
    if active(self) then
        self:drawRect(0, 0, self.width, self.height, 1, 0, 0, 0)
        if drifted(self) then
            local videoW = self.dsVideoW
            layout(self)
            -- A new video size needs the video re-created at that size.
            if videoW and videoW ~= self.dsVideoW and self.listBox.selected > 0 then self:onClickList() end
        end
    end
    return original_prerender(self)
end

local original_restorePosition = SurvivalGuide.restorePosition
function SurvivalGuide:restorePosition()
    if not active(self) then return original_restorePosition(self) end
    self.smallResolution = true
    self.mediumResolution = true
    layout(self)
end

local original_onClickList = SurvivalGuide.onClickList
function SurvivalGuide:onClickList()
    if not active(self) or not self.dsVideoW then return original_onClickList(self) end

    self.selectedItem = self.listBox.items[self.listBox.selected].item

    local text = " <CENTRE> <SIZE:medium> " .. self.selectedItem.title
    if self.selectedItem.video then
        -- Source size stays 960x480; the last two numbers are the size it is drawn at.
        text = text .. string.format(" <VIDEOCENTRE:%s,%u,%u,%u,%u,%s> ", self.selectedItem.video,
            VIDEO_WIDTH, VIDEO_HEIGHT, self.dsVideoW, self.dsVideoH, "")
    end
    if self.selectedItem.spiffo then
        text = text .. self.selectedItem.spiffo
    end
    self.videoRichText.text = text

    if self.selectedItem.description then
        self.descriptionRichText.text = " <SIZE:small> " .. self.selectedItem.description
    else
        self.descriptionRichText.text = ""
    end

    self.descriptionRichText:paginate()
    self.videoRichText:paginate()

    local playable = false
    for _, v in pairs(self.videoRichText.videos or {}) do
        if v then playable = true end
    end
    -- Category pages put their artwork and intro in this slot; only topics with a video that
    -- failed to load collapse it. Picked up by drifted() on the next frame.
    self.dsNoVideo = self.selectedItem.video ~= nil and not playable
end
