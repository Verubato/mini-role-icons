local addonName = ...
local loader
---@type Db
local db
---@class Db
local dbDefaults = {
	Tank = {
		TextureFilePath = "Interface\\AddOns\\MiniRoleIcons\\Icons\\tank.tga",
		Color = {
			R = 1,
			B = 1,
			G = 1,
			A = 1,
		},
		Width = 15,
		Height = 15,
	},
	Healer = {
		TextureFilePath = "Interface\\AddOns\\MiniRoleIcons\\Icons\\healer.tga",
		Color = {
			R = 1,
			B = 1,
			G = 1,
			A = 1,
		},
		Width = 15,
		Height = 15,
	},
	Dps = {
		TextureFilePath = "Interface\\AddOns\\MiniRoleIcons\\Icons\\dps.tga",
		Color = {
			R = 1,
			B = 1,
			G = 1,
			A = 1,
		},
		Width = 15,
		Height = 15,
	},
}

local function Notify(msg)
	local formatted = string.format("%s - %s", addonName, msg)
	print(formatted)
end

local function CopyTable(src, dst)
	if type(dst) ~= "table" then
		dst = {}
	end

	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyTable(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end

	return dst
end

local function UpdateRoleIcon(icon, unit)
	local role = UnitGroupRolesAssigned(unit)
	local settings

	if role == "TANK" then
		settings = db.Tank or dbDefaults.Tank
	elseif role == "HEALER" then
		settings = db.Healer or dbDefaults.Healer
	elseif role == "DAMAGER" then
		settings = db.Dps or dbDefaults.Dps
	else
		return
	end

	local color = settings.Color

	icon:SetTexture(settings.TextureFilePath)
	icon:SetVertexColor(color.R or 1, color.G or 1, color.B or 1, color.A or 1)
	icon:SetSize(settings.Width or 10, settings.Height or 10)

	-- show the entire texture
	icon:SetTexCoord(0, 1, 0, 1)

	-- don't call show here, as blizzard/suf may have hidden it for pet/target frames
end

local function OnUpdateRoleIcon(frame)
	if not frame or not frame.roleIcon or not frame.unit then
		return
	end

	local unit = frame.unit
	local icon = frame.roleIcon

	UpdateRoleIcon(icon, unit)
end

local function OnSufUpdateRoleIcon(_, frame)
	if not frame or not frame.unit or not frame.indicators or not frame.indicators.lfdRole then
		return
	end

	if not frame.indicators.lfdRole.enabled then
		return
	end

	local unit = frame.unit
	local icon = frame.indicators.lfdRole

	UpdateRoleIcon(icon, unit)
end

local function InitDb()
	MiniRoleIconsDB = MiniRoleIconsDB or {}
	db = CopyTable(dbDefaults, MiniRoleIconsDB)
end

local function OnAddonLoaded(_, _, name)
	if name ~= addonName then
		return
	end

	InitDb()
end

loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", OnAddonLoaded)

if not CompactUnitFrame_UpdateRoleIcon then
	Notify("Missing CompactUnitFrame_UpdateRoleIcon")
else
	hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", OnUpdateRoleIcon)
end

-- if shadowed unit frames is enabled
if ShadowUF then
	local indicatorModule = ShadowUF.modules["indicators"]

	if indicatorModule and indicatorModule.UpdateLFDRole then
		hooksecurefunc(indicatorModule, "UpdateLFDRole", OnSufUpdateRoleIcon)
	end
end
