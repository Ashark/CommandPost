--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.CorrectionsBar ===
---
--- The Correction selection/management bar at the top of the ColorInspector
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local MenuButton                        = require("cp.ui.MenuButton")
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CorrectionsBar = {}

local sort = table.sort

--- cp.apple.finalcutpro.inspector.color.ColorInspector.CORRECTION_TYPES
--- Constant
--- Table of Correction Types
CorrectionsBar.CORRECTION_TYPES = {
    ["Color Board"]             = "FFCorrectorColorBoard",
    ["Color Wheels"]            = "PAECorrectorEffectDisplayName",
    ["Color Curves"]            = "PAEColorCurvesEffectDisplayName",
    ["Hue/Saturation Curves"]   = "PAEHSCurvesEffectDisplayName",
}

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function CorrectionsBar.matches(element)
    if element and element:attributeValue("AXRole") == "AXGroup" then
        local children = element:children()
        -- sort them left-to-right
        sort(children, axutils.compareLeftToRight)
        -- log.df("matches: children left to right: \n%s", _inspect(children))
        return #children >= 2
           and children[1]:attributeValue("AXRole") == "AXCheckBox"
           and children[2]:attributeValue("AXRole") == "AXMenuButton"
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:new(parent) -> CorrectionsBar
--- Function
--- Creates a new Media Import object.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new CorrectionsBar object.
-- TODO: Use a function instead of a method.
function CorrectionsBar:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
    }
    prop.extend(o, CorrectionsBar)
    return o
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:parent() -> table
--- Method
--- Returns the Corrections Bar's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function CorrectionsBar:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function CorrectionsBar:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:UI() -> hs._asm.axuielement | nil
--- Method
--- Returns the `hs._asm.axuielement` object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object or `nil`.
function CorrectionsBar:UI()
    return axutils.cache(self, "_ui",
        function()
            local ui = self:parent():topBarUI()
            if ui then
                local barUI = ui[1]
                return CorrectionsBar.matches(barUI) and barUI or nil
            else
                return nil
            end
        end,
        CorrectionsBar.matches
    )
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:isShowing() -> boolean
--- Method
--- Is the Corrections Bar currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function CorrectionsBar:isShowing()
    return self:UI() ~= nil
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:show() -> self
--- Method
--- Attempts to show the bar.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `CorrectionsBar` instance.
function CorrectionsBar:show()
    self:parent():show()
    return self
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:menuButton() -> MenuButton
--- Method
--- Returns the menu button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `menuButton` object.
function CorrectionsBar:menuButton()
    if not self._menuButton then
        self._menuButton = MenuButton:new(self, function()
            return axutils.childWithRole(self:UI(), "AXMenuButton")
        end)
    end
    return self._menuButton
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:findCorrectionLabel(correctionType) -> string
--- Method
--- Returns Correction Label.
---
--- Parameters:
---  * correctionType - The correction type as string.
---
--- Returns:
---  * The correction label as string.
function CorrectionsBar:findCorrectionLabel(correctionType)
    return self:app():string(self.CORRECTION_TYPES[correctionType])
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:activate(correctionType, number) -> cp.apple.finalcutpro.inspector.color.CorrectionsBar
--- Method
--- Activates a correction type.
---
--- Parameters:
---  * `correctionType` - The correction type as string.
---  * `number` - The number of the correction.
---
--- Returns:
---  *  `cp.apple.finalcutpro.inspector.color.CorrectionsBar` object.
function CorrectionsBar:activate(correctionType, number)
    number = number or 1 -- Default to the first corrector.

    self:show()

    --------------------------------------------------------------------------------
    -- See if the correction type/number combo exists already:
    --------------------------------------------------------------------------------
    local correctionText = self:findCorrectionLabel(correctionType)
    if not correctionText then
        log.ef("Invalid Correction Type: %s", correctionType)
    end

    local menuButton = self:menuButton()
    if menuButton:isShowing() then
        local pattern = "%s*"..correctionText.." "..number
        if not menuButton:selectItemMatching(pattern) then
            --------------------------------------------------------------------------------
            -- Try adding a new correction of the specified type:
            --------------------------------------------------------------------------------
            pattern = "%+"..correctionText
            if not menuButton:selectItemMatching(pattern) then
                log.ef("Invalid Correction Type: %s", correctionType)
            end
        end
    end

    return self
end

return CorrectionsBar