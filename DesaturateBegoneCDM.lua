-- Desaturate Begone CDM
-- Prevents icon desaturation in the Cooldown Manager when abilities are on cooldown.
--
-- Uses hooksecurefunc on each individual item frame instance (via the viewer's
-- OnAcquireItemFrame) rather than overriding methods or hooking the mixin table.
-- Hooking the mixin table with hooksecurefunc does NOT change its Lua-visible value,
-- so Mixin() copies would still get the original function. Hooking a specific object
-- with hooksecurefunc IS semantically reliable and does not taint the frame.
local DB_DEFAULTS = {
    enableEssential = true,
    enableUtility = true
}

-- Keyed by viewer name; synced from the DB after ADDON_LOADED fires.
local viewerEnabled = {
    EssentialCooldownViewer = true,
    UtilityCooldownViewer = true
}

-- Applied once per frame instance via hooksecurefunc — safe, does not taint.
local function hookItemFrame(itemFrame)
    if itemFrame._dbHooked then
        return
    end
    itemFrame._dbHooked = true
    hooksecurefunc(itemFrame, "RefreshIconDesaturation", function(self)
        local viewer = self:GetViewerFrame()
        if not viewer then
            return
        end
        if viewerEnabled[viewer:GetName()] then
            self:GetIconTexture():SetDesaturated(false)
        end
    end)
end

-- Hook all currently active frames and intercept future acquisitions.
-- We hook the concrete viewer globals (not the mixin table) so that
-- hooksecurefunc reliably intercepts calls on those specific instances.
local function PatchViewer(viewer)
    for itemFrame in viewer.itemFramePool:EnumerateActive() do
        hookItemFrame(itemFrame)
    end
    hooksecurefunc(viewer, "OnAcquireItemFrame", function(_, itemFrame)
        hookItemFrame(itemFrame)
    end)
end

local hooksApplied = false
local function ApplyHooks()
    if hooksApplied then
        return
    end
    hooksApplied = true
    PatchViewer(EssentialCooldownViewer)
    PatchViewer(UtilityCooldownViewer)
end

local function RefreshViewerPatch(viewerGlobal, dbKey)
    local viewer = _G[viewerGlobal]
    if not viewer or not viewer.itemFramePool then
        return
    end
    viewerEnabled[viewerGlobal] = DesaturateBegoneCDMDB[dbKey]
    for itemFrame in viewer.itemFramePool:EnumerateActive() do
        -- Blizzard's original runs first, then our post-hook fires.
        itemFrame:RefreshIconDesaturation()
    end
end

local function RegisterSettings()
    local category = Settings.RegisterVerticalLayoutCategory("Desaturate Begone CDM")

    local essentialSetting = Settings.RegisterAddOnSetting(category, "DesaturateBegoneCDM_Essential", "enableEssential",
        DesaturateBegoneCDMDB, Settings.VarType.Boolean, "Enable for Essential Cooldowns", DB_DEFAULTS.enableEssential)
    Settings.CreateCheckbox(category, essentialSetting,
        "When checked, icons in the Essential Cooldowns bar will not be desaturated while on cooldown.")
    essentialSetting:SetValueChangedCallback(function(_, value)
        DesaturateBegoneCDMDB.enableEssential = value
        RefreshViewerPatch("EssentialCooldownViewer", "enableEssential")
    end)

    local utilitySetting = Settings.RegisterAddOnSetting(category, "DesaturateBegoneCDM_Utility", "enableUtility",
        DesaturateBegoneCDMDB, Settings.VarType.Boolean, "Enable for Utility Cooldowns", DB_DEFAULTS.enableUtility)
    Settings.CreateCheckbox(category, utilitySetting,
        "When checked, icons in the Utility Cooldowns bar will not be desaturated while on cooldown.")
    utilitySetting:SetValueChangedCallback(function(_, value)
        DesaturateBegoneCDMDB.enableUtility = value
        RefreshViewerPatch("UtilityCooldownViewer", "enableUtility")
    end)

    Settings.RegisterAddOnCategory(category)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "DesaturateBegoneCDM" then
        -- Initialise SavedVariables with defaults.
        if not DesaturateBegoneCDMDB then
            DesaturateBegoneCDMDB = {}
        end
        for k, v in pairs(DB_DEFAULTS) do
            if DesaturateBegoneCDMDB[k] == nil then
                DesaturateBegoneCDMDB[k] = v
            end
        end

        -- Sync the enabled flags from the now-loaded DB.
        viewerEnabled.EssentialCooldownViewer = DesaturateBegoneCDMDB.enableEssential
        viewerEnabled.UtilityCooldownViewer = DesaturateBegoneCDMDB.enableUtility

        RegisterSettings()

        -- Blizzard_CooldownViewer may already be loaded (e.g. after /reload).
        if EssentialCooldownViewer then
            ApplyHooks()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif addonName == "Blizzard_CooldownViewer" then
        ApplyHooks()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
