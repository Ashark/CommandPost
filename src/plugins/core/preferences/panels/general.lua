--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.general ===
---
--- General Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.general",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2000,
        id          = "general",
        label       = i18n("generalPanelLabel"),
        image       = image.imageFromName("NSPreferencesGeneral"),
        tooltip     = i18n("generalPanelTooltip"),
        height      = 400,
    })
end

return plugin