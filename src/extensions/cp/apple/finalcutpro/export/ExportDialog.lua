--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")

local SaveSheet						= require("cp.apple.finalcutpro.export.SaveSheet")
local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

local id							= require("cp.apple.finalcutpro.ids") "ExportDialog"

local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ExportDialog = {}

-- TODO: Add documentation
function ExportDialog.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXModal")
		   and axutils.childWithID(element, id "BackgroundImage") ~= nil
	end
	return false
end

-- TODO: Add documentation
function ExportDialog:new(app)
	local o = {_app = app}
	prop.extend(o, ExportDialog)

	o.UI = app.windowsUI:mutate(function(windowsUI, self)
		return windowsUI and self._findWindowUI(windowsUI)
	end):bind(o)

--- cp.apple.finalcutpro.export.ExportDialog.showing <cp.prop: boolean; read-only>
--- Field
--- Is the window showing?
	o.showing = o.UI:mutate(function(ui, self)
		return ui ~= nil
	end):bind(o)

	return o
end

-- TODO: Add documentation
function ExportDialog:app()
	return self._app
end

-- TODO: Add documentation
function ExportDialog._findWindowUI(windows)
	for i,window in ipairs(windows) do
		if ExportDialog.matches(window) then return window end
	end
	return nil
end

-- Ensures the ExportDialog is showing
function ExportDialog:show()
	if not self:showing() then
		-- open the window
		if self:app():menuBar():isEnabled({"File", "Share", 1}) then
			self:app():menuBar():selectMenu({"File", "Share", 1})
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:hide()
	self:pressCancel()
	return self
end

-- TODO: Add documentation
function ExportDialog:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

-- TODO: Add documentation
function ExportDialog:pressNext()
	local ui = self:UI()
	if ui then
		local nextBtn = ui:defaultButton()
		if nextBtn then
			nextBtn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:saveSheet()
	if not self._saveSheet then
		self._saveSheet = SaveSheet:new(self)
	end
	return self._saveSheet
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.export.ExportDialog:watch() -> string
--- Method
--- Watch for events that happen in the command editor. The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(CommandEditor)` - Triggered when the window is shown.
---    * `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function ExportDialog:watch(events)
	if not self._watcher then
		self._watcher = WindowWatcher:new(self)
	end

	self._watcher:watch(events)
end

-- TODO: Add documentation
function ExportDialog:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return ExportDialog