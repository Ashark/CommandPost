--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspect.color.ColorBoard ===
---
--- Color Board Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")
local geometry							= require("hs.geometry")

local prop								= require("cp.prop")
local just								= require("cp.just")
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")

local Button							= require("cp.ui.Button")
local RadioGroup						= require("cp.ui.RadioGroup")

local Aspect							= require("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")
local Pucker							= require("cp.apple.finalcutpro.inspector.color.ColorPuck")

local id								= require("cp.apple.finalcutpro.ids") "ColorBoard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = {}

local CORRECTION_TYPE					= "Color Board"

--- cp.apple.finalcutpro.inspect.color.ColorBoard.aspect -> table
--- Constant
--- A table containing tables of all the aspect panel settings
ColorBoard.aspect						= {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.aspect.color -> table
--- Constant
--- A table containing the Color Board Color panel settings
ColorBoard.aspect.color					= {
	id 									= 1,
	reset 								= id "ColorReset",
	global 								= { puck = id "ColorGlobalPuck", pct = id "ColorGlobalPct", angle = id "ColorGlobalAngle"},
	shadows 							= { puck = id "ColorShadowsPuck", pct = id "ColorShadowsPct", angle = id "ColorShadowsAngle"},
	midtones 							= { puck = id "ColorMidtonesPuck", pct = id "ColorMidtonesPct", angle = id "ColorMidtonesAngle"},
	highlights 							= { puck = id "ColorHighlightsPuck", pct = id "ColorHighlightsPct", angle = id "ColorHighlightsAngle"}
}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.aspect.saturation -> table
--- Constant
--- A table containing the Color Board Saturation panel settings
ColorBoard.aspect.saturation			= {
	id 									= 2,
	reset 								= id "SatReset",
	global 								= { puck = id "SatGlobalPuck", pct = id "SatGlobalPct"},
	shadows 							= { puck = id "SatShadowsPuck", pct = id "SatShadowsPct"},
	midtones 							= { puck = id "SatMidtonesPuck", pct = id "SatMidtonesPct"},
	highlights 							= { puck = id "SatHighlightsPuck", pct = id "SatHighlightsPct"}
}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.aspect.exposure -> table
--- Constant
--- A table containing the Color Board Exposure panel settings
ColorBoard.aspect.exposure				= {
	id									= 3,
	reset								= id "ExpReset",
	global								= { puck = id "ExpGlobalPuck", pct = id "ExpGlobalPct"},
	shadows 							= { puck = id "ExpShadowsPuck", pct = id "ExpShadowsPct"},
	midtones							= { puck = id "ExpMidtonesPuck", pct = id "ExpMidtonesPct"},
	highlights							= { puck = id "ExpHighlightsPuck", pct = id "ExpHighlightsPct"}
}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.currentAspect -> string
--- Variable
--- The current aspect as a string.
ColorBoard.currentAspect = "*"

--- cp.apple.finalcutpro.inspect.color.ColorBoard.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Color Board or not
---
--- Parameters:
---  * `element`	- The element you want to check
---
--- Returns:
---  * `true` if the `element` is a Color Board otherwise `false`
function ColorBoard.matches(element)
	return ColorBoard.matchesCurrent(element) or ColorBoard.matchesOriginal(colorBoard)
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard.matchesOriginal(element) -> boolean
--- Function
--- Checks to see if a GUI element is the 'original' (pre-10.4) Color Board.
---
--- Parameters:
---  * `element`	- The element you want to check
---
--- Returns:
---  * `true` if the `element` is a pre-10.4 Color Board otherwise `false`
function ColorBoard.matchesOriginal(element)
	if element then
		local group = axutils.childWithRole(element, "AXGroup")
		return group and axutils.childWithID(group, id "BackButton")
	end
	return false
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard.matchesCurrent(element) -> boolean
--- Function
--- Checks to see if a GUI element is the 'current' (10.4+) Color Board.
---
--- Parameters:
---  * `element`	- The element you want to check
---
--- Returns:
---  * `true` if the `element` is a 10.4+ Color Board otherwise `false`
function ColorBoard.matchesCurrent(element)
	for _, child in ipairs(element) do
		local splitGroup = axutils.childWith(child, "AXRole", "AXSplitGroup")
		if splitGroup then
			local colorBoardGroup = axutils.childWith(splitGroup, "AXIdentifier", id "ColorBoardGroup")
			if colorBoardGroup and colorBoardGroup[1] and colorBoardGroup[1][1] and #colorBoardGroup[1][1]:attributeValue("AXChildren") >= 19 then
				log.df("matchesCurrent: true")
				return true
			end
		end
	end
	return false
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:new(parent) -> ColorBoard object
--- Method
--- Creates a new ColorBoard object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorBoard object
function ColorBoard:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	prop.extend(o, ColorBoard)

--- cp.apple.finalcutpro.inspect.color.ColorBoard.isColorInspectorSupported <cp.prop: boolean; read-only>
--- Field
--- Checks if the Color Inspector (from 10.4) is supported.
	o.isColorInspectorSupported = parent:app():inspector():color().isSupported:wrap(o)

	return o
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:parent() -> table
--- Method
--- Returns the ColorBoard's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorBoard:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorBoard:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLORBOARD UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspect.color.ColorBoard:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function ColorBoard:UI()
	return self:parent():correctorUI()
end

function ColorBoard:contentUI()
	return axutils.cache(self, "_content", function()
		local ui = self:UI()
		-- returns the appropriate UI depending on the version.
		return ui and ((#ui == 1 and ui[1]) or ui) or nil
	end)
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:isShowing() -> boolean
--- Method
--- Returns whether or not the Color Board is visible
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is showing, otherwise `false`
ColorBoard.isShowing = prop.new(function(self)
	local ui = self:UI()
	return ui ~= nil and ui:attributeValue("AXSize").w > 0
end):bind(ColorBoard)

--- cp.apple.finalcutpro.inspect.color.ColorBoard:isActive() -> boolean
--- Method
--- Returns whether or not the Color Board is active
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is active, otherwise `false`
ColorBoard.isActive = prop.new(function(self)
	local ui = self:colorSatExpUI()
	return ui ~= nil and axutils.childWith(ui:parent(), "AXIdentifier", id "ColorSatExp")
end):bind(ColorBoard)

--- cp.apple.finalcutpro.inspect.color.ColorBoard:show() -> ColorBoard object
--- Method
--- Shows the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:show()
	if not self:isShowing() then
		self:parent():show()
		if self:isColorInspectorSupported() then
			-----------------------------------------------------------------------
			-- Final Cut Pro 10.4:
			-----------------------------------------------------------------------
			self:parent():show(CORRECTION_TYPE)
		end
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:hide() -> self
--- Method
--- Hides the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:hide()
	if self:backButton():isShowing() then
		self:backButton():press()
	elseif self:isShowing() then
		self:parent():hide()
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:backButton() -> Button
--- Method
--- Returns a `Button` to access the 'Back' button, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Button` for 'back'.
---
--- Notes:
--- * This no longer exists in FCP 10.4+, so will always be non-functional.
function ColorBoard:backButton()
	if not self._backButton then
		self._backButton = Button:new(self, function()
			local group = axutils.childFromTop(self:contentUI(), 1)
			if group and group:attributeValue("AXRole") == "AXGroup" then
				return axutils.childWithID(group, id "BackButton")
			end
		end)
	end
	return self._backButton
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:childUI(id) -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for a child with the specified ID.
---
--- Parameters:
---  * id - `AXIdentifier` of the child
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:childUI(id)
	return axutils.cache(self._child, id, function()
		local ui = self:contentUI()
		return ui and axutils.childWithID(ui, id)
	end)
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:topToolbarUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the top toolbar (i.e. where the Back Button is located in Final Cut Pro 10.3)
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
---
--- Notes:
---  * This object doesn't exist in Final Cut Pro 10.4 as the Color Board is now contained within the Color Inspector
function ColorBoard:topToolbarUI()
	return axutils.cache(self, "_topToolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if axutils.childWith(child, "AXIdentifier", id "BackButton") then
					return child
				end
			end
		end
		return nil
	end)
end

-----------------------------------------------------------------------
--
-- COLOR CORRECTION PANELS:
--
-----------------------------------------------------------------------

function ColorBoard:color()
	if not self._color then
		self._color = Aspect:new(self, 1)
	end
	return self._color
end

function ColorBoard:saturation()
	if not self._saturation then
		self._saturation = Aspect:new(self, 2)
	end
	return self._saturation
end

function ColorBoard:exposure()
	if not self._exposure then
		self._exposure = Aspect:new(self, 3)
	end
	return self._exposure
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:colorSatExpUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the `AXRadioGroup` which houses the "Color", "Saturation" and "Exposure" button
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:colorSatExpUI()
	return axutils.cache(self, "_colorSatExp", function()
		local ui = self:contentUI()
		return ui and axutils.childWith(ui, "AXIdentifier", id "ColorSatExp")
	end)
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:getAspect(aspect, property) -> table
--- Method
--- Gets a table containing the ID information for a specific `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * A table or `nil` if an error occurs
function ColorBoard:getAspect(aspect, property)
	local panel = nil
	if type(aspect) == "string" then
		if aspect == ColorBoard.currentAspect then
			-----------------------------------------------------------------------
			-- Return the currently-visible aspect:
			-----------------------------------------------------------------------
			local ui = self:colorSatExpUI()
			if ui then
				for k,value in pairs(ColorBoard.aspect) do
					if ui[value.id] and ui[value.id]:value() == 1 then
						panel = value
					end
				end
			end
		else
			panel = ColorBoard.aspect[aspect]
		end
	else
		panel = name
	end
	if panel and property then
		return panel[property]
	end
	return panel
end

-----------------------------------------------------------------------
--
-- PANEL CONTROLS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspect.color.ColorBoard:aspectGroup() -> cp.ui.RadioGroup
--- Method
--- Returns the `RadioGroup` for the 'aspect' currently being controlled -
--- either "Color", "Saturation", or "Exposure".
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function ColorBoard:aspectGroup()
	if not self._aspectGroup then
		self._aspectGroup = RadioGroup:new(self, function()
			return axutils.childWithRole(self:contentUI(), "AXRadioGroup")
		end)
	end
	return self._aspectGroup
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:nextAspect() -> ColorBoard object
--- Method
--- Toggles the Color Board Panels between "Color", "Saturation" and "Exposure"
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:nextAspect()
	self:show()

	local aspects = self:aspectGroup()
	aspects:nextOption()

	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:selectedAspect() -> string | nil
--- Method
--- Returns the currently selected Color Board panel
---
--- Parameters:
---  * None
---
--- Returns:
---  * "color", "saturation", "exposure" or `nil` if an error occurs
ColorBoard.selectedAspect = prop(
	function(self)
		local selected = self:aspectGroup():selectedOption()
		return selected and ColorBoard.aspect[selected] or nil
	end,
	function(aspect, self)
		local a = self:getAspect(aspect)
		if a then self:aspectGroup():selectedOption(a.id) end
	end
):bind(ColorBoard)

--- cp.apple.finalcutpro.inspect.color.ColorBoard:showAspect(aspect) -> self
--- Method
--- Shows a specific panel based on the specified `aspect`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:showAspect(aspect)
	self:show()
	self:selectedAspect(aspect)
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:reset(aspect) -> self
--- Method
--- Resets a specified `aspect`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:reset(aspect)
	a = self:getAspect(aspect)
	self:showAspect(aspect)
	local ui = self:contentUI()
	if ui then
		local reset = axutils.childWithID(ui, a.reset)
		if reset then
			reset:doPress()
		end
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:puckUI(aspect, property) -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object of a specific Color Board puck
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:puckUI(aspect, property)
	local details = self:getAspect(aspect, property)
	return self:childUI(details.puck)
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:selectPuck(aspect, property) -> ColorBoard object
--- Method
--- Selects a specific Color Board puck
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:selectPuck(aspect, property)
	self:showAspect(aspect)
	local puckUI = self:puckUI(aspect, property)
	if puckUI then
		local f = puckUI:frame()
		local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		tools.ninjaMouseClick(centre)
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:aspectPropertyPanelUI(aspect, property, type) -> hs._asm.axuielement object
--- Method
--- Ensures that the specified aspect/property panel is visible and returns the specified value type `hs._asm.axuielement` object
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * type			- "pct" or "angle"
---
--- Returns:
---  * An `hs._asm.axuielement` object or `nil` if an error occurs
function ColorBoard:aspectPropertyPanelUI(aspect, property, type)
	if not self:isShowing() then
		return nil
	end
	self:showAspect(aspect)
	local details = self:getAspect(aspect, property)
	if not details or not details[type] then
		return nil
	end
	local ui = self:childUI(details[type])
	if not ui then
		-----------------------------------------------------------------------
		-- Short inspector panels can hide some details panels:
		-----------------------------------------------------------------------
		self:selectPuck(aspect, property)
		-----------------------------------------------------------------------
		-- Try again:
		-----------------------------------------------------------------------
		ui = self:childUI(details[type])
	end
	return ui
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:applyPercentage(aspect, property, value) -> ColorBoard object
--- Method
--- Applies a Color Board Percentage value to the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * value		- value as string
---
--- Returns:
---  * ColorBoard object
function ColorBoard:applyPercentage(aspect, property, value)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		pctUI:setAttributeValue("AXValue", tostring(value))
		pctUI:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:shiftPercentage(aspect, property, shift) -> ColorBoard object
--- Method
--- Shifts a Color Board Percentage value of the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * shift		- number you want to increase/decrease the percentage by
---
--- Returns:
---  * ColorBoard object
function ColorBoard:shiftPercentage(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		ui:setAttributeValue("AXValue", tostring(value + tonumber(shift)))
		ui:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:getPercentage(aspect, property) -> number | nil
--- Method
--- Gets a percentage value of the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Number or `nil` if an error occurred
function ColorBoard:getPercentage(aspect, property)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		return tonumber(pctUI:attributeValue("AXValue"))
	end
	return nil
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:applyAngle(aspect, property, value) -> ColorBoard object
--- Method
--- Applies a Color Board Angle value to the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * value		- value as string
---
--- Returns:
---  * ColorBoard object
function ColorBoard:applyAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		angleUI:setAttributeValue("AXValue", tostring(value))
		angleUI:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:shiftAngle(aspect, property, shift) -> ColorBoard object
--- Method
--- Shifts a Color Board Angle value of the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * shift		- number you want to increase/decrease the angle by
---
--- Returns:
---  * ColorBoard object
function ColorBoard:shiftAngle(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		-----------------------------------------------------------------------
		-- Loop around between 0 and 360 degrees:
		-----------------------------------------------------------------------
		value = (value + shift + 360) % 360
		ui:setAttributeValue("AXValue", tostring(value))
		ui:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:getAngle(aspect, property) -> number | nil
--- Method
--- Gets an angle value of the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Number or `nil` if an error occurred
function ColorBoard:getAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		local value = angleUI:attributeValue("AXValue")
		if value ~= nil then return tonumber(value) end
	end
	return nil
end

--- cp.apple.finalcutpro.inspect.color.ColorBoard:startPucker(aspect, property) -> Pucker object
--- Method
--- Creates a Pucker object for the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Pucker object
function ColorBoard:startPucker(aspect, property)
	if self.pucker then
		self.pucker:cleanup()
		self.pucker = nil
	end
	self.pucker = Pucker:new(self, aspect, property):start()
	return self.pucker
end

return ColorBoard