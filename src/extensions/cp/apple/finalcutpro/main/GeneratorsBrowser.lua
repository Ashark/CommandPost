--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.GeneratorsBrowser ===
---
--- Generators Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local axutils							= require("cp.apple.finalcutpro.axutils")
local tools								= require("cp.tools")
local geometry							= require("hs.geometry")

local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")
local Button							= require("cp.apple.finalcutpro.ui.Button")
local Table								= require("cp.apple.finalcutpro.ui.Table")
local ScrollArea						= require("cp.apple.finalcutpro.ui.ScrollArea")
local CheckBox							= require("cp.apple.finalcutpro.ui.CheckBox")
local PopUpButton						= require("cp.apple.finalcutpro.ui.PopUpButton")
local TextField							= require("cp.apple.finalcutpro.ui.TextField")

local id								= require("cp.apple.finalcutpro.ids") "GeneratorsBrowser"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GeneratorsBrowser = {}

GeneratorsBrowser.TITLE = "Titles and Generators"

-- TODO: Add documentation
function GeneratorsBrowser:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function GeneratorsBrowser:parent()
	return self._parent
end

-- TODO: Add documentation
function GeneratorsBrowser:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- GENERATORSBROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function GeneratorsBrowser:UI()
	if self:isShowing() then
		return axutils.cache(self, "_ui", function()
			return self:parent():UI()
		end)
	end
	return nil
end

-- TODO: Add documentation
function GeneratorsBrowser:isShowing()
	local parent = self:parent()
	return parent:isShowing() and parent:showGenerators():isChecked()
end

-- TODO: Add documentation
function GeneratorsBrowser:show()
	local menuBar = self:app():menuBar()
	-- Go there direct
	menuBar:selectMenu("Window", "Go To", GeneratorsBrowser.TITLE)
	just.doUntil(function() return self:isShowing() end)
	return self
end

-- TODO: Add documentation
function GeneratorsBrowser:hide()
	self:parent():hide()
	just.doWhile(function() return self:isShowing() end)
	return self
end

-----------------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------------

-- TODO: Add documentation
function GeneratorsBrowser:mainGroupUI()
	return axutils.cache(self, "_mainGroup",
	function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXSplitGroup")
	end)
end

-- TODO: Add documentation
function GeneratorsBrowser:sidebar()
	if not self._sidebar then
		self._sidebar = Table:new(self, function()
			return axutils.childWithID(self:mainGroupUI(), id "Sidebar")
		end):uncached()
	end
	return self._sidebar
end

-- TODO: Add documentation
function GeneratorsBrowser:contents()
	if not self._contents then
		self._contents = ScrollArea:new(self, function()
			local group = axutils.childMatching(self:mainGroupUI(), function(child)
				return child:role() == "AXGroup" and #child == 1
			end)
			return group and group[1]
		end)
	end
	return self._contents
end

-- TODO: Add documentation
function GeneratorsBrowser:group()
	if not self._group then
		self._group = PopUpButton:new(self, function()
			return axutils.childWithRole(self:UI(), "AXPopUpButton")
		end)
	end
	return self._group
end

-- TODO: Add documentation
function GeneratorsBrowser:search()
	if not self._search then
		self._search = TextField:new(self, function()
			return axutils.childWithRole(self:mainGroupUI(), "AXTextField")
		end)
	end
	return self._search
end

-- TODO: Add documentation
function GeneratorsBrowser:showSidebar()
	self:app():menuBar():checkMenu("Window", "Show in Workspace", "Sidebar")
end

-- TODO: Add documentation
function GeneratorsBrowser:topCategoriesUI()
	return self:sidebar():rowsUI(function(row)
		return row:attributeValue("AXDisclosureLevel") == 0
	end)
end

-- TODO: Add documentation
function GeneratorsBrowser:showInstalledTitles()
	self:group():selectItem(1)
	return self
end

-- TODO: Add documentation
function GeneratorsBrowser:showInstalledGenerators()
	self:showInstalledTitles()
	return self
end

-- TODO: Add documentation
function GeneratorsBrowser:showAllTitles()
	self:showSidebar()
	local topCategories = self:topCategoriesUI()
	if topCategories and #topCategories == 2 then
		self:sidebar():selectRow(topCategories[1])
	end
	return self
end

-- TODO: Add documentation
function GeneratorsBrowser:showAllGenerators()
	self:showSidebar()
	local topCategories = self:topCategoriesUI()
	if topCategories and #topCategories == 2 then
		self:sidebar():selectRow(topCategories[2])
	end
	return self
end

-- TODO: Add documentation
function GeneratorsBrowser:currentItemsUI()
	return self:contents():childrenUI()
end

-- TODO: Add documentation
function GeneratorsBrowser:selectedItemsUI()
	return self:contents():selectedChildrenUI()
end

-- TODO: Add documentation
function GeneratorsBrowser:itemIsSelected(itemUI)
	local selectedItems = self:selectedItemsUI()
	if selectedItems and #selectedItems > 0 then
		for _,selected in ipairs(selectedItems) do
			if selected == itemUI then
				return true
			end
		end
	end
	return false
end

-- TODO: Add documentation
function GeneratorsBrowser:applyItem(itemUI)
	if itemUI then
		self:contents():showChild(itemUI)
		local targetPoint = geometry.rect(itemUI:frame()).center
		tools.ninjaDoubleClick(targetPoint)
	end
	return self
end

-- TODO: Add documentation
-- Returns the list of titles for all effects/transitions currently visible
function GeneratorsBrowser:getCurrentTitles()
	local contents = self:contents():childrenUI()
	if contents ~= nil then
		return fnutils.map(contents, function(child)
			return child:attributeValue("AXTitle")
		end)
	end
	return nil
end

--------------------------------------------------------------------------------
--
-- LAYOUTS:
--
--------------------------------------------------------------------------------

-- TODO: Add documentation
function GeneratorsBrowser:saveLayout()
	local layout = {}
	if self:isShowing() then
		layout.showing = true
		layout.sidebar = self:sidebar():saveLayout()
		layout.contents = self:contents():saveLayout()
		layout.search = self:search():saveLayout()
	end
	return layout
end

-- TODO: Add documentation
function GeneratorsBrowser:loadLayout(layout)
	if layout and layout.showing then
		self:show()
		self:search():loadLayout(layout.search)
		self:sidebar():loadLayout(layout.sidebar)
		self:contents():loadLayout(layout.contents)
	end
end

return GeneratorsBrowser