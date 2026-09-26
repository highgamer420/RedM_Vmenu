local Menu = CES.Menu

local ALIGN = { 'Left', 'Right' }

local function indexOf(list, value, lower)
    for i, v in ipairs(list) do
        if (lower and v:lower() or v) == value then return i end
    end
    return 1
end

local function pretty(s) return s:sub(1, 1):upper() .. s:sub(2) end

Menu.Register('settings', {
    title = 'Settings',
    build = function(m)
        local st = CES.Settings
        local themes = {}
        for i, t in ipairs(Config.Themes) do themes[i] = pretty(t) end

        m:list({ id = 'theme', label = 'Theme', options = themes, index = indexOf(Config.Themes, st.theme),
            onChange = function(i) st.theme = Config.Themes[i] CES.SaveSettings() end })
        m:list({ id = 'align', label = 'Menu Position', options = ALIGN, index = indexOf(ALIGN, st.align, true),
            onChange = function(i) st.align = ALIGN[i]:lower() CES.SaveSettings() end })
        m:slider({ id = 'scale', label = 'Menu Size', min = 0.7, max = 1.5, step = 0.05, value = st.scale, format = '%.2fx',
            onChange = function(v) st.scale = v CES.SaveSettings() end })
        m:slider({ id = 'visible', label = 'Visible Items', min = 6, max = 18, step = 1, value = st.visibleItems,
            onChange = function(v) st.visibleItems = math.floor(v) CES.SaveSettings() end })
        m:button({ label = 'Reset To Defaults', onSelect = function()
            for k, v in pairs(Config.Defaults) do st[k] = v end
            CES.SaveSettings()
            CES.Notify('Settings reset.', 'success')
        end })

        m:separator('Controls')
        m:button({ label = 'Open / Close', right = Config.Keys.Open or ('/' .. tostring(Config.Commands.Open)), disabled = true })
        m:button({ label = 'Navigate', right = 'Arrows · Enter · Backspace', disabled = true })
        m:button({ label = 'Mouse & Search Mode', right = Config.Keys.MouseMode or '-', disabled = true,
            desc = 'Frees the cursor so you can click items and type to filter the current list. Esc to leave.' })
        m:separator()
        m:button({ label = Config.MenuTitle, right = 'v' .. GetResourceMetadata(GetCurrentResourceName(), 'version', 0), disabled = true })
    end,
})
