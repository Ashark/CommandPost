--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.stabilization ===
---
--- Stabilization Shortcut

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                           = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.stabilization.enable() -> none
--- Function
--- Enables or disables Stabilisation.
---
--- Parameters:
---  * value - `true` to enable, `false` to disable, `nil` to toggle.
---
--- Returns:
---  * None
function mod.enable(value)

	--------------------------------------------------------------------------------
	-- Set Stabilization:
	--------------------------------------------------------------------------------
	local inspector = fcp:inspector():video()
	if type(value) == "boolean" then
		inspector:stabilization(value)
	else
		--------------------------------------------------------------------------------
		-- Toggle:
		--------------------------------------------------------------------------------
		local result = inspector:stabilization()
		inspector:stabilization(not result)
	end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.stabilization",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        local cmds = deps.fcpxCmds
        cmds:add("cpStabilizationToggle")
            :groupedBy("timeline")
            :whenActivated(function() mod.enable() end)

        cmds:add("cpStabilizationEnable")
            :groupedBy("timeline")
            :whenActivated(function() mod.enable(true) end)

        cmds:add("cpStabilizationDisable")
            :groupedBy("timeline")
            :whenActivated(function() mod.enable(false) end)
    end

    return mod
end

return plugin
