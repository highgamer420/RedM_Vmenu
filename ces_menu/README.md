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

| ACE | What it allows |
|---|---|
| `ces_menu.open` | Open the menu (only checked when Config.RequireOpenPermission = true) |
| `ces_menu.self.godmode` | God mode |
| `ces_menu.self.invisible` | Invisibility |
| `ces_menu.self.infinitestamina` | Infinite stamina (core + bar) |
| `ces_menu.self.infinitedeadeye` | Infinite dead eye core |
| `ces_menu.self.noragdoll` | No ragdoll |
| `ces_menu.self.heal` | Heal yourself and fill cores |
| `ces_menu.self.revive` | Revive yourself |
| `ces_menu.self.clean` | Clean dirt, blood and wetness |
| `ces_menu.self.suicide` | Kill yourself |
| `ces_menu.noclip` | Noclip |
| `ces_menu.teleport.waypoint` | Teleport to map waypoint |
| `ces_menu.teleport.locations` | Teleport to preset locations |
| `ces_menu.teleport.coords` | Teleport to typed coordinates |
| `ces_menu.teleport.saved` | Save & use personal teleport locations |
| `ces_menu.weapons.spawn` | Give yourself weapons |
| `ces_menu.weapons.removeall` | Remove all your weapons |
| `ces_menu.weapons.refill` | Refill ammo |
| `ces_menu.weapons.infiniteammo` | Infinite ammo |
| `ces_menu.weapons.customize` | Gunsmith: customize weapon parts, engravings and materials |
| `ces_menu.mounts.spawn` | Spawn horses (incl. add-on horses) |
| `ces_menu.mounts.customize` | Horse customization: saddles, blankets, manes, tails and other tack |
| `ces_menu.mounts.delete` | Delete your horse |
| `ces_menu.mounts.godmode` | Horse god mode |
| `ces_menu.mounts.care` | Heal and clean your horse |
| `ces_menu.vehicles.spawn` | Spawn wagons |
| `ces_menu.vehicles.delete` | Delete your wagon |
| `ces_menu.vehicles.repair` | Repair your wagon |
| `ces_menu.appearance.model` | Change player model & outfit presets (incl. add-on peds) |
| `ces_menu.appearance.clothing` | Clothing & character wardrobe (RDO-style), saved outfits |
| `ces_menu.appearance.scale` | Change ped scale |
| `ces_menu.world.time` | Change server time |
| `ces_menu.world.freezetime` | Freeze server time |
| `ces_menu.world.weather` | Change server weather |
| `ces_menu.players.view` | See the online player list |
| `ces_menu.players.goto` | Teleport to a player |
| `ces_menu.players.bring` | Bring a player to you |
| `ces_menu.players.spectate` | Spectate a player |
| `ces_menu.players.freeze` | Freeze a player |
| `ces_menu.players.heal` | Heal a player |
| `ces_menu.players.revive` | Revive a player |
| `ces_menu.players.kill` | Kill a player |
| `ces_menu.players.message` | Send a private message |
| `ces_menu.players.kick` | Kick a player |
| `ces_menu.players.ban` | Ban a player |
| `ces_menu.players.unban` | View ban list & unban |
| `ces_menu.players.announce` | Send a server-wide announcement |
| `ces_menu.players.immune` | Cannot be targeted by staff who lack this permission |
| `ces_menu.misc.coords` | Show & copy coordinates |
| `ces_menu.misc.nametags` | Overhead player names |
| `ces_menu.misc.blips` | Player blips on the map |
| `ces_menu.misc.deletegun` | Delete gun (shoot entities to delete them) |

## Add-ons (`addons.json`)

This works like vMenu's `addons.json`. Put your streamed or add-on content in the lists, then run `cesmenu_reloadaddons` in the server console. You don't need to restart the resource.
Entries can be a plain model name (`"my_ped"`) or an object with a label and category. Hashes can be hex (`"0x8FFCF06B"`) or names. Copy-ready examples are in the `_examples` block of the file.

| List | Fields | Shows up in |
|---|---|---|
| `peds` | `model`, `label`, `category` | Appearance → add-on category |
| `horses` | `model`, `label` | Spawn Horse → Add-on Horses |
| `wagons` | `model`, `label` | Spawn Wagon → Add-on Wagons |
| `weapons` | `hash`, `label`, `category` | Weapons → add-on category |
| `clothing` | `category`, `label`, `gender` (`male`/`female`/`any`), `hashes` (colour variants) | Wardrobe category, marked ★ |
| `horse_tack` | `category`, `label`, `hashes` | Horse Customization category, marked ★ |
| `weapon_components` | `weapon`, `category`, `component`, `label` | Gunsmith, marked ★ |

Clothing categories: `hats eyewear masks neckwear neckties shirts_full vests coats coats_closed ponchos cloaks gloves gauntlets suspenders belts belt_buckles gunbelts gunbelt_accs holsters_left holsters_right satchels pants skirts dresses chaps spats boots boot_accessories accessories armor badges jewelry_rings_left jewelry_rings_right jewelry_bracelets hair beards_complete beards_mustache heads eyes teeth BODIES_UPPER BODIES_LOWER`

Tack categories: `horse_saddles horse_blankets saddle_horns saddle_stirrups HORSE_SADDLEBAGS horse_bedrolls horse_bridles horse_accessories saddle_lanterns horse_shoes horse_manes HORSE_TAILS horse_mustache`

Other resources can also add content at runtime: `exports.ces_menu:AddAddon('clothing', { category = 'hats', label = 'Event Hat', gender = 'any', hashes = { '0x12345678' } })`.

## Credits

The clothing, horse-tack and weapon-component hash lists in `client/data/` are generated from the community research in [femga/rdr3_discoveries](https://github.com/femga/rdr3_discoveries). Thanks to femga and the contributors.

## Framework hooks (`config.lua`)

```lua
Config.Hooks = {
    Revive = function() TriggerEvent('vorp:resurrectPlayer') end, -- use your framework's revive
    Heal = nil,
    OnHorseSpawned = function(horse) end,  -- e.g. add tack / register ownership
    OnWagonSpawned = function(wagon) end,
}
```

## Exports (client)

```lua
exports.ces_menu:RegisterMenu('my_menu', {
    title = 'My Stuff',
    perms = { 'noclip' },                 -- optional: visible if the player has any of these
    build = function(args)
        return {
            { type = 'button',   label = 'Say hi', onSelect = function() print('hi') end },
            { type = 'checkbox', label = 'Toggle', checked = false, onChange = function(v) end },
            { type = 'list',     label = 'Pick', options = { 'A', 'B' }, onSelect = function(i, opt) end },
            { type = 'slider',   label = 'Amount', min = 0, max = 10, step = 1, onChange = function(v) end },
            { type = 'separator', label = 'Section' },
            { type = 'submenu',  label = 'Deeper', menu = 'other_menu' },
        }
    end,
})
exports.ces_menu:AddMainMenuEntry({ label = 'My Stuff', menu = 'my_menu', desc = 'Shown on the main menu' })

exports.ces_menu:Open()            -- or Open('menu_id')
exports.ces_menu:Close()
exports.ces_menu:IsOpen()
exports.ces_menu:Notify('Hello', 'success')   -- info | success | warning | error
exports.ces_menu:HasPermission('players.kick')
local text = exports.ces_menu:Prompt('Title', 'default', 'placeholder')
```

## Notes

- Several RDR2-specific natives are called by hash (outfits, cores, spawning, weather) and wrapped in `pcall`, so one bad native won't break the menu. Set `Config.Debug = true` to print native failures.
- Town coordinates are approximate centres. The teleport finds the ground height, so only x/y matter.
- Switching to Online Male / Female gives the ped a full base body and a random outfit, which you can then restyle in the wardrobe. Frameworks with their own character creator (VORP/RSG) will usually overwrite wardrobe changes on relog. That's expected.
- "Put back what you had" relies on a native that detects the worn item. If it isn't available on your build, leaving a category after previewing clears that slot instead.
