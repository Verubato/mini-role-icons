local _, addon = ...
---@type MiniFramework
local mini = addon.Framework
local config = addon.Config
---@type Db
local db
local icons = {}
-- texture path per role, and the IconsPath they were built from. blizzard runs the role icon
-- update for every group frame it refreshes, so build the path once rather than on each one
local iconPaths = {}
local iconPathsBuiltFrom

---@return number? r
---@return number? g
---@return number? b
local function GetClassColor(unit)
	local _, classTag = UnitClass(unit)

	-- a secret class can't be used as a table key
	if mini:IsSecret(classTag) then
		return nil
	end

	local color = classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]

	if not color then
		return nil
	end

	-- loose values rather than a table; this runs per frame per refresh
	return color.r, color.g, color.b
end

local function GetIconPath(role)
	if iconPathsBuiltFrom ~= db.IconsPath then
		wipe(iconPaths)
		iconPathsBuiltFrom = db.IconsPath
	end

	local path = iconPaths[role]

	if not path then
		path = db.IconsPath .. role .. ".tga"
		iconPaths[role] = path
	end

	return path
end

local function UpdateRoleIcon(icon, unit, isRefresh)
	local role = UnitGroupRolesAssigned(unit)

	-- 12.0 hands out the arena roles as secret values, which can't be compared or concatenated,
	-- so leave those icons as blizzard drew them
	if mini:IsSecret(role) then
		return
	end

	if not role or role == "NONE" then
		return
	end

	local path = GetIconPath(role)
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

	-- captured once, while the icon still holds what blizzard drew. capturing again later
	-- would store our own texture as the original, and disabling would restore it to itself
	if not original then
		original = {}
		icon.MriOriginal = original

		original.Texture = icon:GetTexture()
		original.Coord = { icon:GetTexCoord() }
		original.Color = { icon:GetVertexColor() }
		original.Size = { icon:GetSize() }
	end

	-- blizzard's role update sets the texcoord and visibility but leaves the texture file the
	-- template gave it, so after the first pass this is already ours and the swap is the one
	-- expensive call here
	if icon:GetTexture() ~= path then
		icon:SetTexture(path)
	end

	if db.ClassColorsEnabled then
		local r, g, b = GetClassColor(unit)

		if r then
			icon:SetVertexColor(r, g, b, 1)
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
	db = mini:GetSavedVars(config.DbDefaults)
	config:Init()

	if not CompactUnitFrame_UpdateRoleIcon then
		mini:NotifyWithPrefix("Missing CompactUnitFrame_UpdateRoleIcon")
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
