--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    H E L P   &   S U P P O R T   M E N U                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.menu.helpandsupport ===
---
--- The Help & Support menu section.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY                  = 8888888
local PREFERENCES_PRIORITY      = 8
local SETTING                   = "menubarHelpEnabled"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local sectionEnabled = config.prop(SETTING, true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.menu.helpandsupport",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]               = "manager",
        ["core.preferences.panels.menubar"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

    --------------------------------------------------------------------------------
    -- Create the Timeline section:
    --------------------------------------------------------------------------------
    local section = dependencies.manager.addSection(PRIORITY)

    --------------------------------------------------------------------------------
    -- Disable the section if the Timeline option is disabled:
    --------------------------------------------------------------------------------
    section:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

    --------------------------------------------------------------------------------
    -- Add the separator and title for the section:
    --------------------------------------------------------------------------------
    section
        :addSeparator(0)
        :addItem(1, function()
            return { title = string.upper(i18n("helpAndSupport")) .. ":", disabled = true }
        end)

    --------------------------------------------------------------------------------
    -- Add to General Preferences Panel:
    --------------------------------------------------------------------------------
    local prefs = dependencies.prefs
    prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
        {
            label = i18n("show") .. " " .. i18n("helpAndSupport"),
            onchange = function(_, params) sectionEnabled(params.checked) end,
            checked = sectionEnabled,
        }
    )

    return section
end

return plugin