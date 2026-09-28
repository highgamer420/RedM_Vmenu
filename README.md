# Support Discord https://discord.gg/rCBt6hwcWP 

# SHOP other RedM scripts https://crazy-eyes-studio-redm.tebex.store

# 📚 Documentation https://docs.crazyeyesstudio.com/redm/ces-menu

# CES Menu (RedM)

A standalone admin and trainer menu for **RedM**, by Crazy Eyes Studio. It covers the same ground as vMenu for FiveM, but it's written for RDR2, and every option has its own ACE permission.

- **Standalone Lua.** Needs no framework. Optional hooks for VORP / RSG revive, heal and spawn logic.
- **Per-option ACE permissions.** Staff checks happen on the server, so a modified client can't skip them.
- **Themed NUI menu.** Four themes (Western, Parchment, Midnight, Blood), left or right position, adjustable size. Each player's settings are saved.
- **You can move while it's open.** Arrow keys and controller navigation, like vMenu. Press **Left Alt** for mouse mode, which also lets you type to filter the current list.
- **Extendable.** Other resources can add their own menus and main-menu entries through exports.

## Install

1. Drop `ces_menu` into your `resources` folder.
2. In `server.cfg`:
   ```
   ensure ces_menu
   exec @ces_menu/permissions.cfg
   ```
3. Add yourself as admin in `permissions.cfg` (`add_principal identifier.license:... group.admin`).
4. Review `config.lua`. **If you already run weathersync or another time script, set `Config.World.Enabled = false`.**

OneSync is recommended; the player tools work best with it.

## Controls

| Action | Default |
|---|---|
| Open / close | `F4` or `/cesmenu` |
| Navigate | Arrow keys / D-pad, Enter, Backspace |
| Change list / slider | Left / Right |
| Mouse + search mode | `Left Alt` (Esc to leave) |
| Noclip | `/noclip` (optional hotkey in `Config.Keys.Noclip`) |
| Noclip movement | W A S D, E / Space up, Q down, Shift fast, Ctrl slow |

## Features

- **Self:** god mode, invisibility, infinite stamina / dead eye, no ragdoll, noclip with speed levels, heal (fills cores), revive, clean up, suicide
- **Online players:** teleport to, bring, spectate (loads out-of-scope players under OneSync), freeze, heal, revive, kill, private message, kick, timed or permanent ban
- **Teleport:** waypoint (finds the ground automatically), 15 town presets, typed coordinates, personal saved locations (rename / overwrite / copy / delete). Takes your horse or wagon with you.
- **Weapons:** by category, give all, refill ammo, infinite ammo, remove all
- **Gunsmith:** customize the weapon in your hands like RDO. Barrels, grips, sights, clips, and shared materials and engravings for frame, barrel, cylinder and trigger. Your choices are saved per weapon and reapplied when you draw it.
- **Horses & wagons:** 23 horses, 18 wagons, custom models, horse god mode, heal & clean horse, repair / delete wagon
- **Horse customization (RDO stable):** saddles, blankets, horns, stirrups, saddlebags, bedrolls, bridles, lanterns, masks, manes, tails and mustaches, about 870 styles in all. Items preview as you scroll and ← → changes colour. Saved tack sets are included, and newly spawned horses can get your last tack automatically.
- **Appearance:** story / online / townsfolk / animal models, custom model, outfit presets, random outfit, ped scale, restore original model
- **Clothing & character (RDO wardrobe):** hats, coats, shirts, vests, pants, boots, gun belts, holsters, jewelry and more, plus hair, beards, heads, eyes and bodies. That's about 3,000 styles each for Online Male and Online Female, and a story-ped set for male story peds. Items preview as you scroll, colour variants cycle with ← →, and leaving a category without equipping puts back what you had. Saved outfits and "keep outfit after respawn" are included.
- **Add-ons (`addons.json`):** add your own peds, horses, wagons, weapons, clothing items, horse tack and weapon parts without touching code (see below).
- **World:** server-synced time (presets, hour slider, freeze) and weather with smooth transitions
- **Admin tools:** server announcements, ban list with unban, delete gun
- **Misc:** coordinates HUD, copy coords (vector3 / vector4 / Lua table / JSON), overhead name tags, player blips
- **Bans:** stored in `data/bans.json`. Matched against identifiers and hardware tokens (IP optional). Players are kicked with the reason and time remaining.
- **Logging:** console, plus an optional Discord webhook for every staff action
- **Immunity:** staff with `players.immune` can't be targeted by staff who don't have it

## Permissions

Each option below has its own ACE. ACE is hierarchical: `ces_menu` grants everything, and `ces_menu.players` grants every player action.
`Config.PublicPermissions` gives options to everyone. `Config.DisabledPermissions` turns options off for everyone, admins included.
After editing ACEs on a live server, run `cesmenu_refreshperms`. Players also get fresh permissions each time they open the menu.

