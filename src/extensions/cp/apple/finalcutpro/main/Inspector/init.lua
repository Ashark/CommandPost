--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector ===
---
--- Inspector

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("inspector")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local AudioInspector					= require("cp.apple.finalcutpro.main.Inspector.AudioInspector")
local ColorInspector					= require("cp.apple.finalcutpro.main.Inspector.ColorInspector")
local EffectInspector					= require("cp.apple.finalcutpro.main.Inspector.EffectInspector")
local GeneratorInspector				= require("cp.apple.finalcutpro.main.Inspector.GeneratorInspector")
local InfoInspector						= require("cp.apple.finalcutpro.main.Inspector.InfoInspector")
local ShareInspector					= require("cp.apple.finalcutpro.main.Inspector.ShareInspector")
local TextInspector						= require("cp.apple.finalcutpro.main.Inspector.TextInspector")
local TitleInspector					= require("cp.apple.finalcutpro.main.Inspector.TitleInspector")
local TransitionInspector				= require("cp.apple.finalcutpro.main.Inspector.TransitionInspector")
local VideoInspector					= require("cp.apple.finalcutpro.main.Inspector.VideoInspector")

local id								= require("cp.apple.finalcutpro.ids") "Inspector"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Inspector = {}

--- cp.apple.finalcutpro.main.Inspector.INSPECTOR_TABS -> table
--- Constant
--- Table of supported Inspector Tabs
Inspector.INSPECTOR_TABS = {
	["Audio"] 		= "FFInspectorTabAudio",
	["Color"] 		= "FFInspectorTabColor",
	["Effect"] 		= "FFInspectorTabMotionEffectEffect",
	["Generator"] 	= "FFInspectorTabGenerator",
	["Info"] 		= "FFInspectorTabMetadata",
	["Share"] 		= "FFInspectorTabShare",
	["Text"] 		= "FFInspectorTabMotionEffectText",
	["Title"] 		= "FFInspectorTabMotionEffectTitle",
	["Transition"] 	= "FFInspectorTabMotionEffectTransition",
	["Video"] 		= "FFInspectorTabMotionEffectVideo",
}

--- cp.apple.finalcutpro.main.Inspector.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - axuielementObject
---
--- Returns:
---  * `true` if matches otherwise `false`
function Inspector.matches(element)
	return axutils.childWith(element, "AXIdentifier", id "DetailsPanel") ~= nil -- is inspecting
		or axutils.childWith(element, "AXIdentifier", id "NothingToInspect") ~= nil 	-- nothing to inspect
end

--- cp.apple.finalcutpro.main.Inspector:new(parent) -> Inspector
--- Method
--- Creates a new Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:new(parent)
	local o = {_parent = parent}
	prop.extend(o, Inspector)

--- cp.apple.finalcutpro.main.Inspector.UI <cp.prop: axuielement; read-only>
--- Field
--- Returns the Inspector's `axuielement`.
	o.UI = prop(function(self)
		ui = self:parent():rightGroupUI()
		if ui then
			-----------------------------------------------------------------------
			-- It's in the right panel (full-height):
			-----------------------------------------------------------------------
			if Inspector.matches(ui) then
				return ui
			end
		else
			-----------------------------------------------------------------------
			-- It's in the top-left panel (half-height):
			-----------------------------------------------------------------------
			local top = self:parent():topGroupUI()
			if top then
				for i,child in ipairs(top) do
					if Inspector.matches(child) then
						return child
					end
				end
			end
		end
		return nil
	end):bind(o)
	:monitor(parent.rightGroupUI)
	:monitor(parent.topGroupUI)

--- cp.apple.finalcutpro.main.Inspector.showing <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the Inspector is showing otherwise `false`.
	o.showing = o.UI:mutate(function(ui, self)
		return ui ~= nil
	end):bind(o)

	return o
end

--- cp.apple.finalcutpro.main.Inspector:parent() -> Parent
--- Method
--- Returns the parent of the Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.Inspector:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- INSPECTOR UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:show([tab]) -> Inspector
--- Method
--- Shows the inspector.
---
--- Parameters:
---  * [tab] - A string from the `cp.apple.finalcutpro.main.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * The `Inspector` instance.
---
--- Notes:
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:show(tab)
	if tab and Inspector.INSPECTOR_TABS[tab] then
		self:selectTab(tab)
	else
		local parent = self:parent()
		-----------------------------------------------------------------------
		-- Show the parent:
		-----------------------------------------------------------------------
		if parent:show() then
			local menuBar = self:app():menuBar()
			-----------------------------------------------------------------------
			-- Enable it in the primary:
			-----------------------------------------------------------------------
			menuBar:checkMenu({"Window", "Show in Workspace", "Inspector"})
		end
	end
	return self
end

--- cp.apple.finalcutpro.main.Inspector:hide() -> Inspector
--- Method
--- Hides the inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Inspector` instance.
function Inspector:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu({"Window", "Show in Workspace", "Inspector"})
	return self
end

--- cp.apple.finalcutpro.main.Inspector:selectTab([tab]) -> boolean or nil
--- Method
--- Selects a tab in the inspector.
---
--- Parameters:
---  * [tab] - A string from the `cp.apple.finalcutpro.main.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if an error occurred.
---
--- Notes:
---  * This method will open the Inspector if it's closed, and leave it open.
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectTab(value)
	if not value and not Inspector.INSPECTOR_TABS[value] then
		log.ef("selectTab requires a valid tab string: %s", value)
		return nil
	end
	if not self.showing() then
		self:show()
		if not self.showing() then
			log.ef("Failed to open Inspector")
			return nil
		end
	end
	local ui = self:UI()
	if ui then
		for _,child in ipairs(ui) do
			local app = self:app()
			for _,subChild in ipairs(child) do
				local title = subChild:attributeValue("AXTitle")
				local result = false
				if title == app:string("FFInspectorTabMotionEffectVideo") and value == "Video" then
					result = true
				elseif title == app:string("FFInspectorTabGenerator") and value == "Generator" then
					result = true
				elseif title == app:string("FFInspectorTabMetadata") and value == "Info" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectEffect") and value == "Effect" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectText") and value == "Text" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectTitle") and value == "Title" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectTransition") and value == "Transition" then
					result = true
				elseif title == app:string("FFInspectorTabAudio") and value == "Audio" then
					result = true
				elseif title == app:string("FFInspectorTabShare") and value == "Share" then
					result = true
				elseif title == app:string("FFInspectorTabColor") and value == "Color" then
					result = true
				end
				if result then
					local actionResult = subChild:performAction("AXPress")
					if actionResult then
						return true
					else
						return nil
					end
				end
			end
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.Inspector:selectedTab() -> string or nil
--- Method
--- Returns the name of the selected inspector tab otherwise `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if the Inspector is closed or an error occurred.
---
--- Notes:
---  * The tab strings can be:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectedTab()
	local ui = self:UI()
	if ui then
		for _,child in ipairs(ui) do
			local app = self:app()
			for _,subChild in ipairs(child) do
				local title = subChild:attributeValue("AXTitle")
				local value = subChild:attributeValue("AXValue")
				if title and value == 1 then
					if title == app:string("FFInspectorTabMotionEffectVideo") then
						return "Video"
					elseif title == app:string("FFInspectorTabGenerator") then
						return "Generator"
					elseif title == app:string("FFInspectorTabMetadata") then
						return "Info"
					elseif title == app:string("FFInspectorTabMotionEffectEffect") then
						return "Effect"
					elseif title == app:string("FFInspectorTabMotionEffectText") then
						return "Text"
					elseif title == app:string("FFInspectorTabMotionEffectTitle") then
						return "Title"
					elseif title == app:string("FFInspectorTabMotionEffectTransition") then
						return "Transition"
					elseif title == app:string("FFInspectorTabAudio") then
						return "Audio"
					elseif title == app:string("FFInspectorTabShare") then
						return "Share"
					elseif title == app:string("FFInspectorTabColor") then
						return "Color"
					end
				end
			end
		end
	end
	return nil
end

-----------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:videoInspector() -> VideoInspector
--- Method
--- Gets the VideoInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector
function Inspector:videoInspector()
	if not self._videoInspector then
		self._videoInspector = VideoInspector:new(self)
	end
	return self._videoInspector
end

-----------------------------------------------------------------------
--
-- GENERATOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:generatorInspector() -> GeneratorInspector
--- Method
--- Gets the GeneratorInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * GeneratorInspector
function Inspector:generatorInspector()
	if not self._generatorInspector then
		self._generatorInspector = GeneratorInspector:new(self)
	end
	return self._generatorInspector
end

-----------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:infoInspector() -> InfoInspector
--- Method
--- Gets the InfoInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * InfoInspector
function Inspector:infoInspector()
	if not self._infoInspector then
		self._infoInspector = InfoInspector:new(self)
	end
	return self._infoInspector
end

-----------------------------------------------------------------------
--
-- EFFECT INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:effectInspector() -> EffectInspector
--- Method
--- Gets the EffectInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * EffectInspector
function Inspector:effectInspector()
	if not self._effectInspector then
		self._effectInspector = EffectInspector:new(self)
	end
	return self._effectInspector
end

-----------------------------------------------------------------------
--
-- TEXT INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:textInspector() -> TextInspector
--- Method
--- Gets the TextInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TextInspector
function Inspector:textInspector()
	if not self._textInspector then
		self._textInspector = TextInspector:new(self)
	end
	return self._textInspector
end

-----------------------------------------------------------------------
--
-- TITLE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:titleInspector() -> TitleInspector
--- Method
--- Gets the TitleInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TitleInspector
function Inspector:titleInspector()
	if not self._titleInspector then
		self._titleInspector = TitleInspector:new(self)
	end
	return self._titleInspector
end

-----------------------------------------------------------------------
--
-- TRANSITION INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:transitionInspector() -> TransitionInspector
--- Method
--- Gets the TransitionInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TransitionInspector
function Inspector:transitionInspector()
	if not self._transitionInspector then
		self._transitionInspector = TransitionInspector:new(self)
	end
	return self._transitionInspector
end

-----------------------------------------------------------------------
--
-- AUDIO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:audioInspector() -> AudioInspector
--- Method
--- Gets the AudioInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * AudioInspector
function Inspector:audioInspector()
	if not self._audioInspector then
		self._audioInspector = AudioInspector:new(self)
	end
	return self._audioInspector
end

-----------------------------------------------------------------------
--
-- SHARE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:shareInspector() -> ShareInspector
--- Method
--- Gets the ShareInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ShareInspector
function Inspector:shareInspector()
	if not self._shareInspector then
		self._shareInspector = ShareInspector:new(self)
	end
	return self._shareInspector
end

-----------------------------------------------------------------------
--
-- COLOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector:colorInspector() -> ColorInspector
--- Method
--- Gets the ColorInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector
function Inspector:colorInspector()
	if not self._colorInspector then
		self._colorInspector = ColorInspector:new(self)
	end
	return self._colorInspector
end

return Inspector