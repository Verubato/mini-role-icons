-- Drives the role icon swap through the CompactUnitFrame_UpdateRoleIcon hook and addon:Refresh,
-- the only two public entry points UpdateRoleIcon has.
--
-- The mock's issecretvalue always answers false (see build/Lua/WowMock.lua), so the secret
-- branches below swap it out for one that recognises a chosen sentinel as the only secret
-- value, exactly where a real secret role or class tag would arrive.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

---Overrides one or more globals for the duration of fn, restoring them even if fn raises,
---so one failing assertion can't leave a later test running against a patched global.
---@param overrides table<string, any>
---@param fn fun()
local function WithGlobals(overrides, fn)
	local reals = {}

	for name, value in pairs(overrides) do
		reals[name] = _G[name]
		_G[name] = value
	end

	local ok, err = pcall(fn)

	for name, value in pairs(reals) do
		_G[name] = value
	end

	if not ok then
		error(err, 0)
	end
end

local function NewFrame(unit, role)
	_G.UnitGroupRolesAssigned = function()
		return role
	end

	return {
		unit = unit,
		roleIcon = WowMock.NewFrame("Texture"),
	}
end

fw.describe("MiniRoleIcons - GetIconPath", function()
	local context
	local db

	fw.before_each(function()
		context = harness.Run("MiniRoleIcons")
		db = _G.MiniRoleIconsDB
	end)

	fw.it("builds the icon texture from the configured path and role", function()
		local frame = NewFrame("party1", "TANK")

		_G.CompactUnitFrame_UpdateRoleIcon(frame)

		fw.eq(frame.roleIcon:GetTexture(), db.IconsPath .. "TANK.tga", "path built from IconsPath and role")
	end)

	fw.it("reuses the same built path for a second unit sharing a role", function()
		local first = NewFrame("party1", "HEALER")
		_G.CompactUnitFrame_UpdateRoleIcon(first)

		local second = NewFrame("party2", "HEALER")
		_G.CompactUnitFrame_UpdateRoleIcon(second)

		fw.eq(second.roleIcon:GetTexture(), first.roleIcon:GetTexture(), "same role, same built path")
	end)

	fw.it("rebuilds the path once IconsPath changes", function()
		local frame = NewFrame("party1", "DAMAGER")
		_G.CompactUnitFrame_UpdateRoleIcon(frame)

		local before = frame.roleIcon:GetTexture()

		db.IconsPath = "Interface\\AddOns\\MiniRoleIcons\\Icons\\Custom\\"
		context.Addon:Refresh()

		fw.neq(frame.roleIcon:GetTexture(), before, "path rebuilt against the new IconsPath")
		fw.eq(frame.roleIcon:GetTexture(), db.IconsPath .. "DAMAGER.tga", "rebuilt path matches the new IconsPath")
	end)
end)

fw.describe("MiniRoleIcons - GetClassColor", function()
	local db

	fw.before_each(function()
		harness.Run("MiniRoleIcons")
		db = _G.MiniRoleIconsDB
		db.ClassColorsEnabled = true
	end)

	fw.it("colors the icon from RAID_CLASS_COLORS for a known class", function()
		_G.UnitClass = function()
			return "Warrior", "WARRIOR"
		end

		local frame = NewFrame("party1", "TANK")
		_G.CompactUnitFrame_UpdateRoleIcon(frame)

		local r, g, b = frame.roleIcon:GetVertexColor()
		local expected = _G.RAID_CLASS_COLORS.WARRIOR

		fw.eq(r, expected.r, "red channel matches the class color")
		fw.eq(g, expected.g, "green channel matches the class color")
		fw.eq(b, expected.b, "blue channel matches the class color")
	end)

	fw.it("falls back to white when the class tag is secret", function()
		-- The sentinel is a real class tag, so a guard that failed to fire would resolve
		-- RAID_CLASS_COLORS.WARRIOR and paint the icon warrior-red instead of white.
		local sentinel = "WARRIOR"

		_G.UnitClass = function()
			return "Warrior", sentinel
		end

		local frame = NewFrame("party1", "TANK")

		WithGlobals({
			issecretvalue = function(v)
				return v == sentinel
			end,
		}, function()
			_G.CompactUnitFrame_UpdateRoleIcon(frame)
		end)

		local r, g, b, a = frame.roleIcon:GetVertexColor()

		fw.eq(r, 1, "GetClassColor returned nil, so red stayed at white")
		fw.eq(g, 1, "green stayed at white")
		fw.eq(b, 1, "blue stayed at white")
		fw.eq(a, 1, "alpha stayed at white")
	end)
end)

fw.describe("MiniRoleIcons - UpdateRoleIcon enable/disable round trip", function()
	local context
	local db

	fw.before_each(function()
		context = harness.Run("MiniRoleIcons")
		db = _G.MiniRoleIconsDB
	end)

	fw.it("captures the original texture before swapping and restores it once disabled", function()
		local frame = NewFrame("party1", "TANK")
		frame.roleIcon:SetTexture("Interface\\Blizzard\\OriginalRoleIcon")
		frame.roleIcon:SetSize(20, 20)

		_G.CompactUnitFrame_UpdateRoleIcon(frame)

		fw.eq(frame.roleIcon:GetTexture(), db.IconsPath .. "TANK.tga", "swapped to our own icon")

		db.IconsEnabled = false
		context.Addon:Refresh()

		fw.eq(frame.roleIcon:GetTexture(), "Interface\\Blizzard\\OriginalRoleIcon", "restored to blizzard's texture")

		local width, height = frame.roleIcon:GetSize()

		fw.eq(width, 20, "restored width")
		fw.eq(height, 20, "restored height")
	end)

	fw.it("does not restore an icon that was never swapped", function()
		db.IconsEnabled = false

		local frame = NewFrame("party1", "TANK")
		frame.roleIcon:SetTexture("Interface\\Blizzard\\OriginalRoleIcon")

		_G.CompactUnitFrame_UpdateRoleIcon(frame)

		fw.eq(frame.roleIcon:GetTexture(), "Interface\\Blizzard\\OriginalRoleIcon", "never touched, so nothing to restore")
	end)
end)

fw.describe("MiniRoleIcons - secret role guard", function()
	fw.it("leaves the icon untouched when the role is secret", function()
		local sentinel = {}
		harness.Run("MiniRoleIcons")
		local db = _G.MiniRoleIconsDB

		db.IconsEnabled = true

		_G.UnitGroupRolesAssigned = function()
			return sentinel
		end

		local frame = {
			unit = "party1",
			roleIcon = WowMock.NewFrame("Texture"),
		}
		frame.roleIcon:SetTexture("Interface\\Blizzard\\OriginalRoleIcon")

		WithGlobals({
			issecretvalue = function(v)
				return v == sentinel
			end,
		}, function()
			_G.CompactUnitFrame_UpdateRoleIcon(frame)
		end)

		fw.eq(frame.roleIcon:GetTexture(), "Interface\\Blizzard\\OriginalRoleIcon", "secret role returned before any swap")
	end)

	fw.it("still skips the icon on a later refresh while the role stays secret", function()
		local sentinel = {}
		local context = harness.Run("MiniRoleIcons")
		local db = _G.MiniRoleIconsDB

		db.IconsEnabled = true

		_G.UnitGroupRolesAssigned = function()
			return sentinel
		end

		local frame = {
			unit = "party1",
			roleIcon = WowMock.NewFrame("Texture"),
		}
		frame.roleIcon:SetTexture("Interface\\Blizzard\\OriginalRoleIcon")

		WithGlobals({
			issecretvalue = function(v)
				return v == sentinel
			end,
		}, function()
			fw.no_error(function()
				_G.CompactUnitFrame_UpdateRoleIcon(frame)
				context.Addon:Refresh()
			end, "a secret role on both the hook call and the refresh it queues")
		end)

		fw.eq(frame.roleIcon:GetTexture(), "Interface\\Blizzard\\OriginalRoleIcon", "still untouched after the refresh")
	end)
end)
