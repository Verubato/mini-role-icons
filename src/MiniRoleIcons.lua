local _, addon = ...
---@type MiniFramework
local mini = addon.Framework
local config = addon.Config
---@type Db
local db
local icons = {}

local function GetClassColor(unit)
	local _, classTag = UnitClass(unit)
	local color = classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]
	return color and { R = color.r, G = color.g, B = color.b, A = 1 }
end

local function UpdateRoleIcon(icon, unit, isRefresh)
	local role = UnitGroupRolesAssigned(unit)

	if not role or role == "NONE" then
		return
	end

	local path = db.IconsPath .. role .. ".tga"
	local original = icon.MriOriginal

	if not db.IconsEnabled then
		if isRefresh and original then
			-- restore the original
			icon:SetTexture(original.Texture)
			icon:SetSize(original.Size[1], original.Size[2])
			icon:SetVertexColor(original.Color[1], original.Color[2], original.Color[3], original.Color[4])

			-- yes coord[3] is skipped on purpose
			local left, top, bottom, right = original.Coord[1], original.Coord[2], original.Coord[4], original.Coord[5]

			icon:SetTexCoord(left, right, top, bottom)

			-- set to nil so we don't keep restoring this icon over the top of whatever it may change to
			icon.MriOriginal = nil
		end

		return
	end

	if not isRefresh or not original then
		icon.MriOriginal = icon.MriOriginal or {}

		original = icon.MriOriginal

		original.Texture = icon:GetTexture()
		original.Coord = { icon:GetTexCoord() }
		original.Color = { icon:GetVertexColor() }
		-- store the size once, as we change the size we don't want to overwrite what the original size was
		original.Size = original.Size or { icon:GetSize() }
	end

	icon:SetTexture(path)

	if db.ClassColorsEnabled then
		local color = GetClassColor(unit)

		if color then
			icon:SetVertexColor(color.R or 1, color.G or 1, color.B or 1, color.A or 1)
		end
	else
		icon:SetVertexColor(1, 1, 1, 1)
	end

	-- show the entire texture
	icon:SetTexCoord(0, 1, 0, 1)

	-- replace the existing icon
	icon:SetSize(db.IconsWidth or 10, db.IconsHeight or 10)

	-- don't call show here, as blizzard/suf may have hidden it for pet/target frames
end

local function OnUpdateRoleIcon(frame)
	if not frame or not frame.roleIcon or not frame.unit then
		return
	end

	local unit = frame.unit
	local icon = frame.roleIcon

	UpdateRoleIcon(icon, unit, false)

	icons[unit] = icon
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

	UpdateRoleIcon(icon, unit, false)

	icons[unit] = icon
end

local function OnAddonLoaded()
	db = mini:GetSavedVars(dbDefaults)
	config:Init()

	if not CompactUnitFrame_UpdateRoleIcon then
		mini:Notify("Missing CompactUnitFrame_UpdateRoleIcon")
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
end

function addon:Refresh()
	for unit, icon in pairs(icons) do
		UpdateRoleIcon(icon, unit, true)
	end
end

mini:WaitForAddonLoad(OnAddonLoaded)
