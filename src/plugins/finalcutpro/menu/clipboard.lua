--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        C L I P B O A R D    M E N U                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The CLIPBOARD menu section.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local metadata					= require("cp.config")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 					= 2500
local PREFERENCES_PRIORITY		= 26
local SETTING 					= "menubarClipboardEnabled"

--------------------------------------------------------------------------------
-- LOCAL FUNCTIONS:
--------------------------------------------------------------------------------
	local function isSectionDisabled()
		local setting = metadata.get(SETTING)
		if setting ~= nil then
			return not setting
		else
			return false
		end
	end

	local function toggleSectionDisabled()
		local menubarEnabled = metadata.get(SETTING)
		metadata.set(SETTING, not menubarEnabled)
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.clipboard",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.manager"] 				= "manager",
		["core.preferences.panels.menubar"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

	--------------------------------------------------------------------------------
	-- Create the Clipboard section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Clipboard option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(isSectionDisabled)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("clipboard")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY, function()
		return { title = i18n("show") .. " " .. i18n("clipboard"),	fn = toggleSectionDisabled, checked = not isSectionDisabled()}
	end)

	return shortcuts
end

return plugin