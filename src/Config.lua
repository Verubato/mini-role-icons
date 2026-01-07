local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local verticalSpacing = 20
local horizontalSpacing = 40
---@type Db
local db
---@class Db
local dbDefaults = {
	IconsPath = "Interface\\AddOns\\MiniRoleIcons\\Icons\\Pwr\\",
	IconsEnabled = true,
	IconsWidth = 15,
	IconsHeight = 15,
	ClassColorsEnabled = false,
}

local M = {
	DbDefaults = dbDefaults,
}
addon.Config = M

function M:Init()
	db = mini:GetSavedVars(dbDefaults)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = mini:AddCategory(panel)

	if not category then
		return
	end

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOPLEFT", title, 0, -verticalSpacing)
	description:SetText("Configure the role icons used on unit frames.")

	local reloadButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	reloadButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, verticalSpacing)
	reloadButton:SetWidth(100)
	reloadButton:SetText("Reload")
	reloadButton:SetScript("OnClick", function()
		ReloadUI()
	end)
	reloadButton:SetShown(false)

	local enabledChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Custom Icons",
		Tooltip = "Use our custom icons. Note this may require a reload when disabling.",
		GetValue = function()
			return db.IconsEnabled
		end,
		SetValue = function(enabled)
			db.IconsEnabled = enabled

			if not enabled then
				reloadButton:SetShown(true)
			end

			addon:Refresh()
		end,
	})

	enabledChkBox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)

	local classColorsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Class Colors",
		Tooltip = "Use class colours for the role icons",
		GetValue = function()
			return db.ClassColorsEnabled
		end,
		SetValue = function(enabled)
			db.ClassColorsEnabled = enabled
			addon:Refresh()
		end,
	})

	classColorsChkBox:SetPoint("LEFT", enabledChkBox.Text, "RIGHT", horizontalSpacing, 0)

	local widthSlider, widthEditBox = mini:CreateSlider({
		Parent = panel,
		LabelText = "Width",
		Min = 1,
		Max = 100,
		Step = 1,
		GetValue = function()
			return tonumber(db.IconsWidth) or dbDefaults.IconsWidth
		end,
		SetValue = function(value)
			if db.IconsWidth == value then
				return
			end

			db.IconsWidth = mini:ClampInt(value, 1, 100, dbDefaults.IconsWidth)
			addon:Refresh()
		end,
	})

	widthSlider:SetPoint("TOPLEFT", enabledChkBox, "BOTTOMLEFT", 0, -verticalSpacing * 2)

	local heightSlider, heightEditBox = mini:CreateSlider({
		Parent = panel,
		LabelText = "Height",
		Min = 1,
		Max = 100,
		Step = 1,
		GetValue = function()
			return tonumber(db.IconsHeight) or dbDefaults.IconsHeight
		end,
		SetValue = function(value)
			if db.IconsHeight == value then
				return
			end

			db.IconsHeight = mini:ClampInt(value, 1, 100, dbDefaults.IconsHeight)
			addon:Refresh()
		end,
	})

	heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -verticalSpacing * 2)

	mini:WireTabNavigation({
		widthEditBox,
		heightEditBox,
	})

	SLASH_MINIROLEICONS1 = "/miniroleicons"
	SLASH_MINIROLEICONS2 = "/miniri"
	SLASH_MINIROLEICONS3 = "/mri"

	mini:RegisterSlashCommand(category, panel)
end
