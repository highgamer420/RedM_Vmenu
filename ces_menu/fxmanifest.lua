fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'ces_menu'
author 'Crazy Eyes Studio'
description 'CES Menu - a standalone, permission-driven admin & trainer menu built for RedM'
version '1.1.0'

shared_scripts {
    'config.lua',
    'shared/keys.lua',
    'shared/permissions.lua',
}

server_scripts {
    'server/main.lua',
    'server/bans.lua',
    'server/world.lua',
    'server/actions.lua',
    'server/addons.lua',
}

client_scripts {
    'client/core.lua',
    'client/utils.lua',
    'client/menu.lua',
    'client/addons.lua',
    'client/data/components.lua',
    'client/data/weapon_components.lua',
    'client/features/toggles.lua',
    'client/features/noclip.lua',
    'client/features/spectate.lua',
    'client/features/overlays.lua',
    'client/features/world.lua',
    'client/features/customizer.lua',
    'client/menus/main.lua',
    'client/menus/self.lua',
    'client/menus/players.lua',
    'client/menus/teleport.lua',
    'client/menus/weapons.lua',
    'client/menus/mounts.lua',
    'client/menus/appearance.lua',
    'client/menus/wardrobe.lua',
    'client/menus/tack.lua',
    'client/menus/gunsmith.lua',
    'client/menus/world.lua',
    'client/menus/admin.lua',
    'client/menus/misc.lua',
    'client/menus/settings.lua',
    'client/exports.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
