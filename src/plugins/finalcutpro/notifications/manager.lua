--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 N O T I F I C A T I O N S     M A N A G E R                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.notifications.manager ===
---
--- Notifications Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local distributednotifications                  = require("hs.distributednotifications")
local fs                                        = require("hs.fs")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local plist                                     = require("cp.plist")
local watcher                                   = require("cp.watcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.notifications.manager
--- Constant
--- Event Types
mod.EVENT_TYPES = {"success", "failure"}

-- findNotificationInfo(path) -> string
-- Function
-- Find Notification Information
--
-- Parameters:
--  * path - Path to the ShareStatus.plist file
--
-- Returns:
--  * Notification Information as string
local function findNotificationInfo(path)
    local plistPath = path .. "/ShareStatus.plist"
    if fs.attributes(plistPath) then
        local shareStatus = plist.fileToTable(plistPath)
        if shareStatus then
            local latestType = nil
            local latestInfo = nil

            for type,results in pairs(shareStatus) do
                local info = results[#results]
                if latestInfo == nil or latestInfo.fullDate < info.fullDate then
                    latestInfo = info
                    latestType = type
                end
            end

            if latestInfo then
                --------------------------------------------------------------------------------
                -- Put the first resultStr into a top-level value to make it easier for i18n:
                --------------------------------------------------------------------------------
                if latestInfo.resultStr then
                    latestInfo.result = latestInfo.resultStr[1]
                end
                local message = i18n("shareDetails_"..latestType, latestInfo)
                if not message then
                    message = i18n("shareUnknown", {type = latestType})
                end
                return message
            end
        end
    end
    return i18n("shareUnknown", {type = "unknown"})
end

-- notificationWatcherAction(name, object) -> none
-- Function
-- Notification Watcher Action
--
-- Parameters:
--  * name - Status Name as string
--  * path - Path to the ShareStatus.plist file
--
-- Returns:
--  * None
local function notificationWatcherAction(name, path)
    -- FOR DEBUGGING/DEVELOPMENT
    -- log.df(string.format("name: %s\npath: %s\nuserInfo: %s\n", name, path, hs.inspect(userInfo)))

    local message
    if name == "uploadSuccess" then
        local info = findNotificationInfo(path)
        message = i18n("shareSuccessful", {info = info})
        mod.watchers:notify("success", message)
    elseif name == "ProTranscoderDidFailNotification" then
        message = i18n("shareFailed")
        mod.watchers:notify("failure", message)
    else
        --------------------------------------------------------------------------------
        -- Unexpected result:
        --------------------------------------------------------------------------------
        return
    end
end

-- ensureWatching() -> none
-- Function
-- Notification Watcher
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function ensureWatching()
    if mod.successWatcher == nil then
        --------------------------------------------------------------------------------
        -- SHARE SUCCESSFUL NOTIFICATION WATCHER:
        --------------------------------------------------------------------------------
        -- NOTE: ProTranscoderDidCompleteNotification doesn't seem to trigger when exporting small clips.
        mod.successWatcher = distributednotifications.new(notificationWatcherAction, "uploadSuccess")
        mod.successWatcher:start()

        --------------------------------------------------------------------------------
        -- SHARE UNSUCCESSFUL NOTIFICATION WATCHER:
        --------------------------------------------------------------------------------
        mod.failureWatcher = distributednotifications.new(notificationWatcherAction, "ProTranscoderDidFailNotification")
        mod.failureWatcher:start()
    end
end

-- checkWatching() -> none
-- Function
-- Check Watching
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function checkWatching()
    if mod.watchers:getCount() == 0 and mod.successWatcher ~= nil then
        mod.successWatcher:stop()
        mod.successWatcher = nil
        mod.failureWatcher:stop()
        mod.failureWatcher = nil
    end
end

--- plugins.finalcutpro.notifications.manager.watchers -> watcher
--- Variable
--- Watchers
mod.watchers = watcher.new(table.unpack(mod.EVENT_TYPES))

--- plugins.finalcutpro.notifications.manager.watch(event) -> string
--- Function
--- Start Watchers
---
--- Parameters:
---  * events - Events to watch
---
--- Returns:
---  * The ID of the watcher as string
function mod.watch(events)
    local id = mod.watchers:watch(events)
    ensureWatching()
    return id
end

--- plugins.finalcutpro.notifications.manager.unwatch(id) -> none
--- Function
--- Start Watchers
---
--- Parameters:
---  * id - The ID of the watcher to unwatch as string
---
--- Returns:
---  * None
function mod.unwatch(id)
    mod.watchers:unwatch(id)
    checkWatching()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.notifications.manager",
    group = "finalcutpro",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init()
    return mod
end

return plugin
