-- Die Surviving: fit the crafting window (ISHandcraftWindow) into the bottom screen.
--
-- Its width is the sum of its columns' minimums (categories | recipe list | recipe details), about
-- 890 canvas px against ~744 available at render scale 0.6. Two columns are wider than they need
-- to be on a narrow screen:
--  * the recipe list grows to fit its longest recipe tooltip line;
--  * the craft control row in the details column puts the quantity controls and "Time Required"
--    side by side in two equal halves, so its minimum is twice the wider half. Here it stacks them.
--  * the filter panel above the recipe list puts "Show All Recipes", "Sort by:" and the sort combo
--    on one row, and sizes the tickbox from its text key rather than its label (vanilla bug, which
--    happens to make room for the label it forgot to count). Here the tickbox gets its own row and
--    its real width, so the recipe list's floor is the search row.
--  * the recipe list's icon-grid view (kept in the same column even while hidden) wants at least
--    5 tile columns; 4 here.
--  * the details column (ISCraftRecipePanel) has a fixed 350 px floor that the stacked craft row
--    no longer needs; lowered so the content decides.

require "Entity/ISUI/CraftRecipe/ISWidgetRecipeListPanel"
require "Entity/ISUI/CraftRecipe/ISWidgetHandCraftControl"
require "Entity/ISUI/CraftRecipe/ISWidgetRecipeFilterPanel"
require "Entity/ISUI/CraftRecipe/ISCraftRecipePanel"
require "Entity/ISUI/CraftRecipe/ISWidgetRecipesPanel"
require "DieSurviving/DS_Layout"

local DS = DieSurviving

-- Same values as the locals at the top of ISWidgetHandCraftControl.lua.
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 5
local BUTTON_HGT = FONT_HGT_SMALL + 6

local original_filterChildren = ISWidgetRecipeFilterPanel.createChildren
function ISWidgetRecipeFilterPanel:createChildren()
    original_filterChildren(self)
    if not DS.active(0) then return end
    local tm = getTextManager()
    if self.showAllRecipeTickBox then
        self.showAllRecipeTickBox:setWidth(BUTTON_HGT + tm:MeasureStringX(UIFont.Small, getText("IGUI_CraftingUI_ShowAllRecipe")))
    end
    if self.tickBoxShowAllVersion then
        self.tickBoxShowAllVersion:setWidth(BUTTON_HGT + tm:MeasureStringX(UIFont.Small, getText("IGUI_CraftingUI_ShowAllVersion")))
    end
end

-- Same values as the locals at the top of ISWidgetRecipeFilterPanel.lua (NewSmall, not Small).
local FILTER_BUTTON_HGT = getTextManager():getFontHeight(UIFont.NewSmall) + 6
local SEARCH_MIN_WIDTH = 60

local original_filterLayout = ISWidgetRecipeFilterPanel.calculateLayout
function ISWidgetRecipeFilterPanel:calculateLayout(_preferredWidth, _preferredHeight)
    if not DS.active(0) then return original_filterLayout(self, _preferredWidth, _preferredHeight) end
    local S = UI_BORDER_SPACING
    local x = S + 1

    -- Filter and sort combos share a width, as in vanilla.
    if self.filterTypeCombo and self.sortCombo then
        local widthDiff = self.viewModeButton:getWidth() + S
        local targetWidth = math.max(self.sortCombo:getWidth(), self.filterTypeCombo:getWidth() + widthDiff)
        self.filterTypeCombo:setWidth(targetWidth - widthDiff);
        self.sortCombo:setWidth(targetWidth);
    end

    -- Widest of: search row, sort row, tickbox row.
    local rightBlock = self.viewModeButton:getWidth()
    if self.filterTypeCombo then rightBlock = rightBlock + S + self.filterTypeCombo:getWidth() end
    local sortRow = 0
    if self.sortCombo and self.sortComboLabel then
        sortRow = self.sortComboLabel:getWidth() + S + self.sortCombo:getWidth()
    end
    local tickRow = 0
    if self.showAllRecipeTickBox then tickRow = self.showAllRecipeTickBox:getWidth() end
    if self.tickBoxShowAllVersion then tickRow = math.max(tickRow, self.tickBoxShowAllVersion:getWidth()) end
    self.minimumWidth = 2 * x + math.max(SEARCH_MIN_WIDTH + S + rightBlock, sortRow, tickRow)

    local width = math.max(self.minimumWidth, _preferredWidth or 0);

    -- Row 1: search box | filter combo | view mode button.
    self.viewModeButton:setX(width - self.viewModeButton:getWidth() - x);
    self.viewModeButton:setY(x);
    if self.filterTypeCombo then
        self.filterTypeCombo:setX(self.viewModeButton:getX() - self.filterTypeCombo:getWidth() - S)
        self.filterTypeCombo:setY(self.viewModeButton:getY())
    end
    self.searchEntryBox:setX(x);
    local searchRight = self.filterTypeCombo and self.filterTypeCombo:getX() or self.viewModeButton:getX()
    self.searchEntryBox:setWidth(searchRight - x - S);
    self.searchEntryBox:setY(self.viewModeButton:getY())

    local y = self.searchEntryBox:getBottom() + S;

    -- Row 2: "Sort by:" label and combo, right-aligned.
    if self.sortCombo and self.sortComboLabel then
        self.sortCombo:setX(width - x - self.sortCombo:getWidth())
        self.sortCombo:setY(y);
        self.sortComboLabel:setX(self.sortCombo:getX() - self.sortComboLabel:getWidth() - S);
        self.sortComboLabel:setY(y + ((self.sortCombo:getHeight() - self.sortComboLabel:getHeight())/2));
        y = y + FILTER_BUTTON_HGT + S
    end

    -- Row 3: tickboxes.
    for _, tick in ipairs({ self.showAllRecipeTickBox, self.tickBoxShowAllVersion }) do
        if tick then
            tick:setX(x);
            tick:setY(y);
            y = y + FILTER_BUTTON_HGT + S
        end
    end

    self:setWidth(width);
    self:setHeight(y + 1);
end

local RECIPE_GRID_MIN_COLUMNS = 4

local original_recipesChildren = ISWidgetRecipesPanel.createChildren
function ISWidgetRecipesPanel:createChildren()
    original_recipesChildren(self)
    local grid = self.recipeIconPanel and self.recipeIconPanel.tiledIconListBox
    if DS.active(0) and grid then grid.minimumColumns = RECIPE_GRID_MIN_COLUMNS end
end

local DETAILS_MIN_WIDTH = 280

local original_detailsLayout = ISCraftRecipePanel.calculateLayout
function ISCraftRecipePanel:calculateLayout(w, h)
    if DS.active(0) and self.minimumWidth > DETAILS_MIN_WIDTH then
        self.minimumWidth = DETAILS_MIN_WIDTH
    end
    return original_detailsLayout(self, w, h)
end

local original_listLayout = ISWidgetRecipeListPanel.calculateLayout
function ISWidgetRecipeListPanel:calculateLayout(w, h)
    if not DS.active(0) then return original_listLayout(self, w, h) end
    local expand = self.expandToFitTooltip
    self.expandToFitTooltip = false
    original_listLayout(self, w, h)
    self.expandToFitTooltip = expand
end

local original_controlLayout = ISWidgetHandCraftControl.calculateLayout
function ISWidgetHandCraftControl:calculateLayout(_preferredWidth, _preferredHeight)
    if not DS.active(0) then return original_controlLayout(self, _preferredWidth, _preferredHeight) end

    local width = math.max(self.minimumWidth, _preferredWidth or 0);
    local height = math.max(self.minimumHeight, _preferredHeight or 0);

    local leftSideWidth = self.quantityLabel:getWidth() + self.buttonLess:getWidth() + self.entryBox:getWidth() + self.buttonMore:getWidth() + self.buttonMax:getWidth() + UI_BORDER_SPACING*4
    local rightSideWidth = self.durationLabel and (self.durationLabel:getWidth() + UI_BORDER_SPACING + BUTTON_HGT*2) or 0
    -- Stacked: one column as wide as the wider row.
    local minWidth = UI_BORDER_SPACING*2 + 2 + math.max(self.allowBatchCraft and leftSideWidth or 0, rightSideWidth);

    local rows = 1 -- craft button
    if self.allowBatchCraft then rows = rows + 1 end
    if self.durationLabel and self.progressBar then rows = rows + 1 end
    if self.buttonForceCraft then rows = rows + 1 end
    if self.buttonKnowAllRecipes then rows = rows + 1 end
    local minHeight = rows * (BUTTON_HGT + UI_BORDER_SPACING) + UI_BORDER_SPACING + 2;

    height = math.max(height, minHeight);
    width = math.max(width, minWidth)

    local x = UI_BORDER_SPACING+1;
    local y = x;

    self.quantityLabel:setVisible(self.allowBatchCraft);
    self.buttonLess:setVisible(self.allowBatchCraft);
    self.entryBox:setVisible(self.allowBatchCraft);
    self.buttonMore:setVisible(self.allowBatchCraft);
    self.buttonMax:setVisible(self.allowBatchCraft);

    if self.allowBatchCraft then
        self.quantityLabel:setX(x);
        self.quantityLabel:setY(y);
        self.buttonLess:setX(self.quantityLabel:getRight() + UI_BORDER_SPACING);
        self.buttonLess:setY(y);
        self.entryBox:setX(self.buttonLess:getRight() + UI_BORDER_SPACING);
        self.entryBox:setY(y);
        self.buttonMore:setX(self.entryBox:getRight() + UI_BORDER_SPACING);
        self.buttonMore:setY(y);
        self.buttonMax:setX(self.buttonMore:getRight() + UI_BORDER_SPACING);
        self.buttonMax:setY(y);
        y = y + BUTTON_HGT + UI_BORDER_SPACING
    end

    if self.durationLabel and self.progressBar then
        self.durationLabel:setX(x);
        self.durationLabel:setY(y);
        self.progressBar:setX(self.durationLabel:getRight() + UI_BORDER_SPACING);
        self.progressBar:setWidth(width - self.durationLabel:getRight() - UI_BORDER_SPACING*2 - 1);
        self.progressBar:setY(y);
        y = y + BUTTON_HGT + UI_BORDER_SPACING
    end

    self.buttonCraft:setX(x);
    self.buttonCraft:setWidth(width - UI_BORDER_SPACING*2 - 2);
    self.buttonCraft:setY(y);
    y = self.buttonCraft:getBottom() + UI_BORDER_SPACING;

    if self.buttonForceCraft then
        self.buttonForceCraft:setX(x);
        self.buttonForceCraft:setWidth(self.buttonCraft:getWidth());
        self.buttonForceCraft:setY(y);
        y = self.buttonForceCraft:getBottom() + UI_BORDER_SPACING;
    end

    if self.buttonKnowAllRecipes then
        self.buttonKnowAllRecipes:setX(x);
        self.buttonKnowAllRecipes:setWidth(self.buttonCraft:getWidth());
        self.buttonKnowAllRecipes:setY(y);
    end

    self.boxHeight = height;
    self:setWidth(width);
    self:setHeight(height);

    local joypadState = self:recordJoypadState()
    self.joypadButtonsY = {}
    self.joypadButtons = {}
    self.joypadIndexY = 1
    self.joypadIndex = 1
    if self.buttonLess:isVisible() then
        self:insertNewLineOfButtons(self.buttonLess, self.buttonMore, self.buttonMax)
    end
    self:insertNewLineOfButtons(self.buttonCraft)
    if self.buttonForceCraft then
        self:insertNewLineOfButtons(self.buttonForceCraft)
    end
    self:restoreJoypadState(joypadState)
end
