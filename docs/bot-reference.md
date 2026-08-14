# MiniRoleIcons - bot reference

Version 1.2.4. Interface versions: 120100, 50504, 40402, 38002, 38000,
30405, 20506, 11509 (retail plus the classic client lines). Saved
variables: MiniRoleIconsDB (account-wide).

## What it does

Replaces the role icons (tank / healer / damage) on Blizzard compact
party/raid frames with custom high quality icons, with optional class
colouring and a configurable size. Also supports Shadowed Unit Frames.

## How it works

- Hooks CompactUnitFrame_UpdateRoleIcon and swaps the icon texture for the
  matching file in the icon pack: TANK.tga, HEALER.tga, DAMAGER.tga.
- Icons only change for units that have an assigned role. If
  UnitGroupRolesAssigned returns NONE (common outside dungeons/raids), the
  icon is left alone.
- Shadowed Unit Frames: if SUF is loaded, the addon also hooks its
  "lfdRole" indicator, and only when that indicator is enabled in SUF.
- Before replacing an icon it stores the original texture, size, colour and
  texture coordinates so they can be restored when the feature is disabled.

## Settings

Open with a slash command or Options -> AddOns -> MiniRoleIcons.

| Setting | Type | Default | Range | Effect |
|---|---|---|---|---|
| Custom Icons | checkbox | on | - | Use the custom icons. Tooltip warns disabling may require a reload; unchecking shows a Reload button on the panel. |
| Class Colors | checkbox | off | - | Tint the role icons with each unit's class colour. |
| Width | slider | 15 | 1-100, step 1 | Icon width in pixels. |
| Height | slider | 15 | 1-100, step 1 | Icon height in pixels. |

Hidden saved variable (no UI): MiniRoleIconsDB.IconsPath, default
"Interface\\AddOns\\MiniRoleIcons\\Icons\\Pwr\\". The addon appends the role
name plus ".tga" to this path. Only the "Pwr" icon set ships with the addon.

## Slash commands

/miniroleicons, /miniri, /mri - all open the settings panel.

## Troubleshooting

- "Icons didn't change": the unit probably has no assigned role. Roles are
  assigned in dungeons, raids and via the role check; open-world units
  without a role are untouched.
- "I disabled Custom Icons but the old icons look wrong": restoring originals
  is best-effort; use the Reload button on the panel (or /reload).
- "Not working on Shadowed Unit Frames": enable the LFD role indicator in
  SUF; the addon only recolours/replaces that indicator when SUF has it
  enabled.
- Chat message "Missing CompactUnitFrame_UpdateRoleIcon": the game client
  does not expose the function the addon hooks, so Blizzard frames cannot be
  modified on that client.
- Works on Blizzard compact frames and SUF only; other unit frame addons are
  not supported.
