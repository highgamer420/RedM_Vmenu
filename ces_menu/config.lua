Config = {}

-- ─────────────────────────────────────────────────────────────
--  General
-- ─────────────────────────────────────────────────────────────
Config.Debug        = false
Config.MenuTitle    = 'CES Menu'
Config.MenuSubtitle = 'Crazy Eyes Studio'

-- Key names come from shared/keys.lua. Set a key to false to disable it.
Config.Keys = {
    Open      = 'F4',    -- open / close the menu
    MouseMode = 'LALT',  -- while the menu is open: switch to mouse + search mode
    Noclip    = false,   -- e.g. 'PGUP' for a noclip hotkey (still needs the noclip permission)
}

Config.Commands = {
    Open   = 'cesmenu',  -- /cesmenu
    Noclip = 'noclip',   -- /noclip   (set false to disable)
}

-- Require the ces_menu.open ACE before the menu opens at all.
Config.RequireOpenPermission = false

-- true  = options the player lacks permission for are shown greyed out with a lock
-- false = they are hidden entirely
Config.ShowLockedOptions = false

-- Default look for players who haven't changed their own settings.
Config.Defaults = {
    theme        = 'western',   -- western | parchment | midnight | blood
    align        = 'right',     -- left | right
    scale        = 1.0,
    visibleItems = 10,
}
Config.Themes = { 'western', 'parchment', 'midnight', 'blood' }

-- ─────────────────────────────────────────────────────────────
--  Permissions
--  Everything is ACE based: ces_menu.<permission>. ACE is hierarchical,
--  so "ces_menu" = everything, "ces_menu.players" = every player action.
--  See permissions.cfg for a ready-made admin / moderator / player setup.
-- ─────────────────────────────────────────────────────────────

-- Granted to EVERYONE without any ACE (like vMenu's "permissions mode off", but per option).
Config.PublicPermissions = {
    ['misc.coords'] = true,
}

-- Hard-disabled for everyone, even admins. Server enforced.
Config.DisabledPermissions = {
    -- ['self.suicide'] = true,
}

-- ─────────────────────────────────────────────────────────────
--  Features
-- ─────────────────────────────────────────────────────────────
Config.Noclip = {
    Speeds          = { 0.05, 0.25, 0.6, 1.5, 3.0, 6.0, 12.0 },
    DefaultSpeed    = 3,        -- index into Speeds
    FastMultiplier  = 4.0,      -- hold SHIFT
    SlowMultiplier  = 0.25,     -- hold CTRL
    Invisible       = true,     -- hide yourself from other players while nocliping
}

Config.PedScale = { Min = 0.2, Max = 3.0 }

Config.NameTags = { Distance = 60.0, ShowSelf = false }

Config.MaxSavedLocations = 50

-- Server-side time & weather sync. Turn this OFF if you already run
-- weathersync / another time resource, otherwise they will fight.
Config.World = {
    Enabled        = true,
    MinuteDuration = 2000,      -- real ms per in-game minute (2000 = base game speed)
    StartHour      = 9,
    StartWeather   = 'SUNNY',
    TransitionTime = 15.0,      -- seconds to blend between weathers
    Weathers = {
        'SUNNY', 'HIGHPRESSURE', 'CLOUDS', 'OVERCAST', 'OVERCASTDARK', 'MISTY', 'FOG',
        'DRIZZLE', 'RAIN', 'SHOWER', 'THUNDER', 'THUNDERSTORM', 'HURRICANE', 'SLEET',
        'HAIL', 'SNOWLIGHT', 'SNOW', 'SNOWCLEARING', 'BLIZZARD', 'GROUNDBLIZZARD',
        'WHITEOUT', 'SANDSTORM',
    },
}

Config.Bans = {
    MatchIP     = false,  -- also ban by IP address
    UseTokens   = true,   -- also ban by hardware tokens (harder to evade)
    AppealText  = 'Appeal on our Discord.',
}

Config.Logging = {
    Console = true,
    Webhook = '',         -- Discord webhook URL for staff action logs ('' = off)
    WebhookName = 'CES Menu',
}

-- ─────────────────────────────────────────────────────────────
--  Framework hooks (client side). Leave nil for standalone behaviour.
-- ─────────────────────────────────────────────────────────────
Config.Hooks = {
    -- Revive = function() TriggerEvent('vorp:resurrectPlayer') end,  -- example for VORP (check your framework's event)
    Revive = nil,
    Heal = nil,
    OnHorseSpawned = nil,    -- function(horseEntity) -- e.g. give tack / register ownership
    OnWagonSpawned = nil,    -- function(vehicleEntity)
}

-- ─────────────────────────────────────────────────────────────
--  Content lists
-- ─────────────────────────────────────────────────────────────

-- Teleport locations. Ground height is found automatically, so only x/y
-- matter. Coordinates are approximate town centres - tweak as you like.
Config.Locations = {
    { label = 'Valentine',            x = -283.0,  y = 778.0 },
    { label = 'Saint Denis',          x = 2632.0,  y = -1312.0 },
    { label = 'Rhodes',               x = 1232.0,  y = -1296.0 },
    { label = 'Blackwater',           x = -800.0,  y = -1260.0 },
    { label = 'Strawberry',           x = -1792.0, y = -386.0 },
    { label = 'Annesburg',            x = 2930.0,  y = 1350.0 },
    { label = 'Van Horn',             x = 2976.0,  y = 571.0 },
    { label = 'Emerald Ranch',        x = 1403.0,  y = 297.0 },
    { label = 'Lagras',               x = 2105.0,  y = -621.0 },
    { label = 'Colter',               x = -1354.0, y = 2426.0 },
    { label = 'Wapiti Reservation',   x = 446.0,   y = 2230.0 },
    { label = 'Fort Wallace',         x = 345.0,   y = 1493.0 },
    { label = 'Sisika Penitentiary',  x = 3336.0,  y = -675.0 },
    { label = 'Armadillo',            x = -3666.0, y = -2612.0 },
    { label = 'Tumbleweed',           x = -5517.0, y = -2937.0 },
}

Config.Horses = {
    { label = 'Arabian (White)',                 model = 'A_C_Horse_Arabian_White' },
    { label = 'Arabian (Black)',                 model = 'A_C_Horse_Arabian_Black' },
    { label = 'Turkoman (Gold)',                 model = 'A_C_Horse_Turkoman_Gold' },
    { label = 'Turkoman (Dark Bay)',             model = 'A_C_Horse_Turkoman_DarkBay' },
    { label = 'Thoroughbred (Black Chestnut)',   model = 'A_C_Horse_Thoroughbred_BlackChestnut' },
    { label = 'Thoroughbred (Brindle)',          model = 'A_C_Horse_Thoroughbred_Brindle' },
    { label = 'Missouri Fox Trotter (Amber)',    model = 'A_C_Horse_MissouriFoxTrotter_AmberChampagne' },
    { label = 'Standardbred (Black)',            model = 'A_C_Horse_AmericanStandardbred_Black' },
    { label = 'Andalusian (Perlino)',            model = 'A_C_Horse_Andalusian_Perlino' },
    { label = 'Appaloosa (Leopard)',             model = 'A_C_Horse_Appaloosa_Leopard' },
    { label = 'Ardennes (Bay Roan)',             model = 'A_C_Horse_Ardennes_BayRoan' },
    { label = 'Belgian (Blond Chestnut)',        model = 'A_C_Horse_Belgian_BlondChestnut' },
    { label = 'Shire (Dark Bay)',                model = 'A_C_Horse_Shire_DarkBay' },
    { label = 'Nokota (White Roan)',             model = 'A_C_Horse_Nokota_WhiteRoan' },
    { label = 'Mustang (Grullo Dun)',            model = 'A_C_Horse_Mustang_GrulloDun' },
    { label = 'Kentucky Saddler (Black)',        model = 'A_C_Horse_KentuckySaddle_Black' },
    { label = 'Morgan (Bay)',                    model = 'A_C_Horse_Morgan_Bay' },
    { label = 'Tennessee Walker (Chestnut)',     model = 'A_C_Horse_TennesseeWalker_Chestnut' },
    { label = 'Dutch Warmblood (Choc. Roan)',    model = 'A_C_Horse_DutchWarmblood_ChocolateRoan' },
    { label = 'Hungarian Half-bred (Grey)',      model = 'A_C_Horse_HungarianHalfbred_DarkDappleGrey' },
    { label = 'American Paint (Overo)',          model = 'A_C_Horse_AmericanPaint_Overo' },
    { label = 'Mule',                            model = 'A_C_HorseMule_01' },
    { label = 'Donkey',                          model = 'A_C_Donkey_01' },
}

Config.Wagons = {
    { label = 'Buggy',              model = 'buggy01' },
    { label = 'Fancy Buggy',        model = 'buggy02' },
    { label = 'Cart',               model = 'cart01' },
    { label = 'Farm Cart',          model = 'cart03' },
    { label = 'Coach',              model = 'coach2' },
    { label = 'Fancy Coach',        model = 'coach3' },
    { label = 'Stagecoach',         model = 'stagecoach001x' },
    { label = 'Stagecoach (Guns)',  model = 'stagecoach004x' },
    { label = 'Supply Wagon',       model = 'wagon02x' },
    { label = 'Covered Wagon',      model = 'wagon04x' },
    { label = 'Hunting Wagon',      model = 'huntercart01' },
    { label = 'Chuck Wagon',        model = 'chuckwagon000x' },
    { label = 'Prison Wagon',       model = 'wagonprison01x' },
    { label = 'Police Wagon',       model = 'policewagon01x' },
    { label = 'Army Supply Wagon',  model = 'armysupplywagon' },
    { label = 'Gatling Wagon',      model = 'gatchuck' },
    { label = 'Oil Wagon',          model = 'oilwagon01x' },
    { label = 'Utility Wagon',      model = 'utilliwag' },
}

Config.Weapons = {
    { category = 'Revolvers', items = {
        { label = 'Cattleman Revolver',    hash = 'WEAPON_REVOLVER_CATTLEMAN' },
        { label = 'Schofield Revolver',    hash = 'WEAPON_REVOLVER_SCHOFIELD' },
        { label = 'Double-Action Revolver',hash = 'WEAPON_REVOLVER_DOUBLEACTION' },
        { label = 'LeMat Revolver',        hash = 'WEAPON_REVOLVER_LEMAT' },
    }},
    { category = 'Pistols', items = {
        { label = 'Volcanic Pistol',       hash = 'WEAPON_PISTOL_VOLCANIC' },
        { label = 'Mauser Pistol',         hash = 'WEAPON_PISTOL_MAUSER' },
        { label = 'Semi-Auto Pistol',      hash = 'WEAPON_PISTOL_SEMIAUTO' },
        { label = 'M1899 Pistol',          hash = 'WEAPON_PISTOL_M1899' },
    }},
    { category = 'Repeaters', items = {
        { label = 'Carbine Repeater',      hash = 'WEAPON_REPEATER_CARBINE' },
        { label = 'Lancaster Repeater',    hash = 'WEAPON_REPEATER_WINCHESTER' },
        { label = 'Litchfield Repeater',   hash = 'WEAPON_REPEATER_HENRY' },
        { label = 'Evans Repeater',        hash = 'WEAPON_REPEATER_EVANS' },
    }},
    { category = 'Rifles', items = {
        { label = 'Varmint Rifle',         hash = 'WEAPON_RIFLE_VARMINT' },
        { label = 'Springfield Rifle',     hash = 'WEAPON_RIFLE_SPRINGFIELD' },
        { label = 'Bolt-Action Rifle',     hash = 'WEAPON_RIFLE_BOLTACTION' },
        { label = 'Rolling Block Rifle',   hash = 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK' },
        { label = 'Carcano Rifle',         hash = 'WEAPON_SNIPERRIFLE_CARCANO' },
    }},
    { category = 'Shotguns', items = {
        { label = 'Double-Barrel Shotgun', hash = 'WEAPON_SHOTGUN_DOUBLEBARREL' },
        { label = 'Sawed-Off Shotgun',     hash = 'WEAPON_SHOTGUN_SAWEDOFF' },
        { label = 'Pump-Action Shotgun',   hash = 'WEAPON_SHOTGUN_PUMP' },
        { label = 'Repeating Shotgun',     hash = 'WEAPON_SHOTGUN_REPEATING' },
        { label = 'Semi-Auto Shotgun',     hash = 'WEAPON_SHOTGUN_SEMIAUTO' },
    }},
    { category = 'Melee & Thrown', items = {
        { label = 'Hunting Knife',         hash = 'WEAPON_MELEE_KNIFE' },
        { label = 'Hatchet',               hash = 'WEAPON_MELEE_HATCHET' },
        { label = 'Machete',               hash = 'WEAPON_MELEE_MACHETE' },
        { label = 'Throwing Knives',       hash = 'WEAPON_THROWN_THROWING_KNIVES' },
        { label = 'Tomahawk',              hash = 'WEAPON_THROWN_TOMAHAWK' },
        { label = 'Dynamite',              hash = 'WEAPON_THROWN_DYNAMITE' },
        { label = 'Fire Bottle',           hash = 'WEAPON_THROWN_MOLOTOV' },
    }},
    { category = 'Tools', items = {
        { label = 'Bow',                   hash = 'WEAPON_BOW' },
        { label = 'Lasso',                 hash = 'WEAPON_LASSO' },
        { label = 'Lantern',               hash = 'WEAPON_MELEE_LANTERN' },
        { label = 'Binoculars',            hash = 'WEAPON_KIT_BINOCULARS' },
        { label = 'Camera',                hash = 'WEAPON_KIT_CAMERA' },
        { label = 'Fishing Rod',           hash = 'WEAPON_FISHINGROD' },
    }},
}

Config.PedModels = {
    { category = 'Story', items = {
        { label = 'Arthur Morgan',   model = 'player_zero' },
        { label = 'John Marston',    model = 'player_three' },
        { label = 'Dutch van der Linde', model = 'CS_Dutch' },
        { label = 'Micah Bell',      model = 'CS_MicahBell' },
        { label = 'Javier Escuella', model = 'CS_JavierEscuella' },
        { label = 'Charles Smith',   model = 'CS_CharlesSmith' },
        { label = 'Sadie Adler',     model = 'CS_MrSAdler' },
        { label = 'Hosea Matthews',  model = 'CS_HoseaMatthews' },
        { label = 'Bill Williamson', model = 'CS_BillWilliamson' },
    }},
    { category = 'Online', items = {
        { label = 'Online Male (needs clothing)',   model = 'mp_male' },
        { label = 'Online Female (needs clothing)', model = 'mp_female' },
    }},
    { category = 'Townsfolk & Law', items = {
        { label = 'Valentine Townsman',  model = 'A_M_M_ValTownfolk_01' },
        { label = 'Valentine Townswoman',model = 'A_F_M_ValTownfolk_01' },
        { label = 'Rancher',             model = 'A_M_M_Rancher_01' },
        { label = 'Valentine Deputy',    model = 'S_M_M_ValDeputy_01' },
    }},
    { category = 'Animals', items = {
        { label = 'Wolf',        model = 'A_C_Wolf' },
        { label = 'Grizzly Bear',model = 'A_C_Bear_01' },
        { label = 'Cougar',      model = 'A_C_Cougar_01' },
        { label = 'Deer',        model = 'A_C_Deer_01' },
        { label = 'Buck',        model = 'A_C_Buck_01' },
        { label = 'Coyote',      model = 'A_C_Coyote_01' },
        { label = 'Fox',         model = 'A_C_Fox_01' },
        { label = 'Husky',       model = 'A_C_DogHusky_01' },
        { label = 'Cat',         model = 'A_C_Cat_01' },
        { label = 'Chicken',     model = 'A_C_Chicken_01' },
        { label = 'Pig',         model = 'A_C_Pig_01' },
        { label = 'Cow',         model = 'A_C_Cow' },
    }},
}
