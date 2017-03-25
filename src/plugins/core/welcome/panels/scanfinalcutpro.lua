--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             S C A N    F I N A L    C U T    P R O    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.welcome.panels.scanfinalcutpro  ===
---
--- Scan Final Cut Pro Panel Welcome Screen.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("scanfinalcutpro")

local image										= require("hs.image")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local config									= require("cp.config")
local generate									= require("cp.web.generate")
local template									= require("cp.template")

local generate									= require("cp.web.generate")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- CONTROLLER CALLBACK:
	--------------------------------------------------------------------------------
	local function controllerCallback(message)

		local result = message["body"][1]
		if result == "scanQuit" then
			config.application():kill()
		elseif result == "scanSkip" then
			mod.manager.nextPanel(mod._priority)
		elseif result == "scanFinalCutPro" then
			local scanResult = mod.scanfinalcutpro.scanFinalCutPro()
			if scanResult then
				mod.manager.nextPanel(mod._priority)
			end
			timer.doAfter(0.1, function() mod.manager.webview:hswindow():focus() end)
		end

	end

	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	local function generateContent()

		generate.setWebviewLabel(mod.webviewLabel)

		local result = [[
			<p>]] .. i18n("scanFinalCutProText") .. [[</p>
			<style>
				p.uiItem {
					display:inline;
					padding-left: 10px;
				}
			</style>
			<p>]] .. generate.button({title = i18n("scanFinalCutPro")}, "scanFinalCutPro") .. " " .. generate.button({title = i18n("skip")}, "scanSkip") .. " " .. generate.button({title = i18n("quit")}, "scanQuit") .. "</p>"

		return result

	end

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init(deps)

		mod.webviewLabel = deps.manager.getLabel()

		mod._id 			= "scanfinalcutpro"
		mod._priority		= 40
		mod._contentFn		= generateContent
		mod._callbackFn 	= controllerCallback

		mod.manager = deps.manager
		mod.scanfinalcutpro = deps.scanfinalcutpro

		mod.manager.addPanel(mod._id, mod._priority, mod._contentFn, mod._callbackFn)

		return mod

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.welcome.panels.scanfinalcutpro",
	group			= "core",
	dependencies	= {
		["core.welcome.manager"]					= "manager",
		["finalcutpro.preferences.scanfinalcutpro"] = "scanfinalcutpro",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps)
end

return plugin