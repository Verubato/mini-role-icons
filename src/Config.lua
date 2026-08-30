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
	-- A styled button clashes with the stock Blizzard art around it in the settings screen.
	mini:SetCustomStyling(true, { Button = false })

	db = mini:GetSavedVars(dbDefaults)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = mini:AddCategory(panel)

	if not category then
		return
	end

	local header = mini:PanelHeader({
		Parent = panel,
		Description = "Configure the role icons used on unit frames.",
		-- the description used to hang off the title's top left, so the gap below it
		-- is the offset minus the title's line height
		Gap = verticalSpacing - 16,
		Divider = true,
	})

	local reloadButton = mini:Button({
		Parent = panel,
		Text = "Reload",
		Width = 100,
		OnClick = function()
			ReloadUI()
		end,
	})

	reloadButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, verticalSpacing)
	reloadButton:SetShown(false)

	local enabledChkBox = mini:Checkbox({
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

	enabledChkBox:SetPoint("TOPLEFT", header.Anchor, "BOTTOMLEFT", 0, -verticalSpacing)

	local classColorsChkBox = mini:Checkbox({
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

	local width = mini:Slider({
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

	local widthSlider, widthEditBox = width.Slider, width.EditBox
	widthSlider:SetPoint("TOPLEFT", enabledChkBox, "BOTTOMLEFT", 0, -verticalSpacing * 2)

	local height = mini:Slider({
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

	local heightSlider, heightEditBox = height.Slider, height.EditBox
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
