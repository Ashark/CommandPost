local fcp			= require("hs.finalcutpro")

--- The function

local PRIORITY = 0

local function openFcpx()
	fcp:launch()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.top"] = "top",
	["hs.fcpxhacks.plugins.commands.global"] = "global",
}

function plugin.init(deps)
	local top 		= deps.top
	local global	= deps.global
	
	top:addItem(PRIORITY, function()
		return { title = i18n("open") .. " Final Cut Pro",	fn = openFcpx }
	end)
	
	global:add("FCPXHackLaunchFinalCutPro")
		:titled(i18n("open") .. " Final Cut Pro")
		:activatedBy():ctrl():alt():cmd("l")
		:whenPressedDo(openFcpx)
	
	return openFcpx
end

return plugin