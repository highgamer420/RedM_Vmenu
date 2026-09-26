--[[
    Menu engine.
    Menus are registered as data + a build function. Each time a menu is shown
    (or after any interaction) its build function runs again, so every item
    always reflects live state and current permissions. The NUI only renders;
    all logic lives here in Lua.

    CES.Menu.Register('id', {
        title = 'Title' | function(args) ... end,
        perms = { 'perm.a', 'perm.b' },      -- menu is visible if the player has ANY of these (nil = always)
        visible = function() return true end, -- optional extra condition
        onOpen = function(args) end,          -- runs (in a thread) before the first build, may yield
        onLeave = function(args) end,         -- runs when the menu is popped (Back) or the whole menu closes
        build = function(m, args) m:button{...} end,
        empty = 'Text shown when there are no items',
    })

    Builder item options (all types): id, label, desc, right, perm, disabled, visible
      m:button   { onSelect = function() end }
      m:checkbox { checked = bool, onChange = function(value) end }
      m:list     { options = {...}, index = n, keepIndex = bool, onChange = function(i, opt) end, onSelect = function(i, opt) end }
      any item   { onHover = function(item) end }   -- fires when the item becomes selected (live preview)
                 { noRefresh = true, noRefreshOnChange = true }
      m:slider   { min, max, step, value, format = '%.1f', onChange = function(v) end, onSelect = function(v) end }
      m:submenu  { menu = 'id', args = { key = 'unique', ... } }
      m:separator('Label')
]]

local Menu = {
    defs = {},
    stack = {},
    open = false,
    focus = false,
    prompting = false,
    current = nil,
    memo = {},          -- remembered list/slider positions: [menuKey .. '|' .. itemId] = value
    mainEntries = {},   -- entries added to the main menu by other resources
}
CES.Menu = Menu

function Menu.Register(id, def)
    def.id = id
    Menu.defs[id] = def
end

function Menu.IsVisible(id)
    local d = Menu.defs[id]
    if not d then return false end
    if d.visible and not d.visible() then return false end
    if not d.perms then return true end
    return CES.HasPerm(d.perms)
end

-- ─── Builder ────────────────────────────────────────────────
local Builder = {}
Builder.__index = Builder

local function newBuilder(menuKey)
    return setmetatable({ items = {}, handlers = {}, key = menuKey, n = 0 }, Builder)
end

local function optionLabels(options)
    local out = {}
    for i, o in ipairs(options or {}) do
        out[i] = type(o) == 'table' and (o.label or tostring(o.value)) or tostring(o)
    end
    return out
end

function Builder:add(kind, o)
    if o.visible == false then return end
    self.n = self.n + 1
    local allowed = CES.HasPerm(o.perm)
    if kind == 'submenu' and o.menu and allowed then
        allowed = Menu.IsVisible(o.menu)
        if not allowed and not (Menu.defs[o.menu] and Menu.defs[o.menu].perms) then return end
    end
    if not allowed and not Config.ShowLockedOptions then return end

    local id = tostring(o.id or (kind .. '_' .. self.n))
    local memoKey = self.key .. '|' .. id

    if kind == 'list' then
        if o.keepIndex then
            o.index = Menu.memo[memoKey] or o.index or 1
        else
            o.index = o.index or Menu.memo[memoKey] or 1
        end
        if o.index > #(o.options or {}) then o.index = 1 end
    elseif kind == 'slider' then
        o.value = o.value or Menu.memo[memoKey] or o.min or 0
    end

    o.__type, o.__locked, o.__memo = kind, not allowed, memoKey
    self.handlers[id] = o
    self.items[#self.items + 1] = {
        id = id, type = kind, label = o.label or '', desc = o.desc, right = o.right,
        locked = not allowed, disabled = o.disabled or false,
        checked = o.checked or false,
        options = kind == 'list' and optionLabels(o.options) or nil,
        index = o.index,
        min = o.min, max = o.max, step = o.step, value = o.value, format = o.format,
        hover = o.onHover ~= nil,
    }
end

function Builder:button(o)   self:add('button', o) end
function Builder:checkbox(o) self:add('checkbox', o) end
function Builder:list(o)     self:add('list', o) end
function Builder:slider(o)   self:add('slider', o) end
function Builder:submenu(o)  self:add('submenu', o) end
function Builder:separator(label)
    self.n = self.n + 1
    self.items[#self.items + 1] = { id = 'sep_' .. self.n, type = 'separator', label = label or '' }
end

-- ─── Rendering ──────────────────────────────────────────────
local buildToken = 0

local function resolve(v, args)
    if type(v) == 'function' then return v(args) end
    return v
end

function Menu.Build()
    local top = Menu.stack[#Menu.stack]
    if not top then return end
    local def = Menu.defs[top.id]
    if not def then return end

    buildToken = buildToken + 1
    local token = buildToken
    local b = newBuilder(top.key)
    local ok, err = pcall(def.build, b, top.args or {})
    if not ok then
        print(('[ces_menu] error building menu "%s": %s'):format(top.id, tostring(err)))
        b:button({ label = 'This menu failed to load', desc = tostring(err), disabled = true })
    end
    if token ~= buildToken or not Menu.open then return end

    Menu.current = { id = top.id, key = top.key, handlers = b.handlers }
    SendNUIMessage({
        action = 'menu',
        menu = {
            key = top.key,
            title = resolve(def.title, top.args) or top.id,
            items = b.items,
            empty = def.empty or 'Nothing here.',
            depth = #Menu.stack,
        },
    })
end

function Menu.Refresh()
    if Menu.open and not Menu.prompting then
        CreateThread(Menu.Build)
    end
end

function Menu.Push(id, args)
    if not Menu.defs[id] then return end
    local key = id .. ((args and args.key) and (':' .. tostring(args.key)) or '')
    Menu.stack[#Menu.stack + 1] = { id = id, args = args or {}, key = key }
    local def = Menu.defs[id]
    if def.onOpen then
        SendNUIMessage({ action = 'loading', title = resolve(def.title, args) })
        local ok, err = pcall(def.onOpen, args or {})
        if not ok then print(('[ces_menu] onOpen "%s" failed: %s'):format(id, tostring(err))) end
    end
    Menu.Build()
end

local function leaveTop()
    local top = Menu.stack[#Menu.stack]
    local def = top and Menu.defs[top.id]
    if def and def.onLeave then
        local ok, err = pcall(def.onLeave, top.args or {})
        if not ok then print(('[ces_menu] onLeave "%s" failed: %s'):format(top.id, tostring(err))) end
    end
end

function Menu.Back()
    if #Menu.stack <= 1 then return Menu.Close() end
    leaveTop()
    Menu.stack[#Menu.stack] = nil
    Menu.Build()
end

function Menu.Open()
    if Menu.open then return end
    if Config.RequireOpenPermission and not CES.HasPerm('open') then
        return CES.Notify('You are not allowed to use this menu.', 'error')
    end
    Menu.open = true
    SendNUIMessage({ action = 'open' })
    if #Menu.stack == 0 then
        Menu.Push('main', {})
    else
        Menu.Build()
    end
    -- refresh permissions in the background in case ACEs changed
    CreateThread(function()
        local perms = CES.Callback('getPerms')
        if type(perms) == 'table' then
            CES.Perms = perms
            Menu.Refresh()
        end
    end)
end

function Menu.Close()
    if not Menu.open then return end
    CreateThread(leaveTop)
    Menu.open = false
    Menu.SetFocus(false)
    SendNUIMessage({ action = 'close' })
end

function Menu.Toggle()
    if Menu.open then Menu.Close() else CreateThread(Menu.Open) end
end

function Menu.ResetTo(id, args)
    Menu.stack = {}
    Menu.Push(id or 'main', args or {})
end

function Menu.SetFocus(state)
    Menu.focus = state
    if not Menu.prompting then SetNuiFocus(state, state) end
    SendNUIMessage({ action = 'focus', value = state })
end

-- ─── Interaction from NUI ───────────────────────────────────
function Menu.HandleInteract(data)
    local cur = Menu.current
    if not cur or data.menu ~= cur.key then return end
    local o = cur.handlers[data.id]
    if not o then return end
    if o.__locked then return CES.Notify('You do not have permission for this option.', 'error') end
    if o.disabled then return end

    local kind = o.__type
    if kind == 'submenu' then
        if o.onSelect then o.onSelect() end
        return Menu.Push(o.menu, o.args)
    elseif kind == 'button' then
        if o.onSelect then o.onSelect() end
    elseif kind == 'checkbox' then
        if o.onChange then o.onChange(not o.checked) end
    elseif kind == 'list' then
        local idx = tonumber(data.value) or o.index or 1
        Menu.memo[o.__memo] = idx
        o.index = idx
        if data.kind == 'change' then
            if o.onChange then o.onChange(idx, o.options[idx]) end
        elseif o.onSelect then
            o.onSelect(idx, o.options[idx])
        end
    elseif kind == 'slider' then
        local v = tonumber(data.value) or o.value
        Menu.memo[o.__memo] = v
        o.value = v
        if data.kind == 'change' then
            if o.onChange then o.onChange(v) end
        elseif o.onSelect then
            o.onSelect(v)
        end
    end

    if o.noRefresh or (data.kind == 'change' and o.noRefreshOnChange) then return end
    if Menu.open and Menu.current == cur then Menu.Build() end
end

function Menu.HandleHover(data)
    local cur = Menu.current
    if not cur or data.menu ~= cur.key then return end
    local o = cur.handlers[data.id]
    if o and o.onHover and not o.__locked then o.onHover(o) end
end

RegisterNUICallback('hover', function(data, cb)
    cb({})
    CreateThread(function() Menu.HandleHover(data) end)
end)

RegisterNUICallback('interact', function(data, cb)
    cb({})
    CreateThread(function() Menu.HandleInteract(data) end)
end)

RegisterNUICallback('back', function(_, cb)
    cb({})
    CreateThread(Menu.Back)
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    Menu.Close()
end)

RegisterNUICallback('exitFocus', function(_, cb)
    cb({})
    Menu.SetFocus(false)
end)

-- ─── Text prompt ────────────────────────────────────────────
local prompts, promptId = {}, 0

--- Ask the player for text. Returns the string, or nil if cancelled. Call from a thread.
function CES.Prompt(title, default, placeholder, maxLength)
    promptId = promptId + 1
    local id = promptId
    local p = promise.new()
    prompts[id] = p
    Menu.prompting = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'prompt', id = id, title = title, value = default or '',
        placeholder = placeholder or '', maxLength = maxLength or 250,
    })
    local value = Citizen.Await(p)
    Menu.prompting = false
    SetNuiFocus(Menu.focus, Menu.focus)
    if value == nil then return nil end
    value = tostring(value)
    if value:gsub('%s', '') == '' then return nil end
    return value
end

RegisterNUICallback('prompt', function(data, cb)
    cb({})
    local p = prompts[data.id]
    if p then
        prompts[data.id] = nil
        p:resolve(data.value)
    end
end)

--- Yes / no confirmation using the prompt box.
function CES.Confirm(title)
    local v = CES.Prompt(title .. '  (type YES to confirm)', '', 'YES')
    return v and v:upper() == 'YES'
end

-- ─── Keyboard / controller navigation ───────────────────────
local NAV = {
    up = 0x6319DB71, down = 0x05CA7C52, left = 0xA65EBAB4, right = 0xDEB34313,
    select = 0xC7B5340A, back = 0x156F7119,
}
local REPEATS = { up = true, down = true, left = true, right = true }

CreateThread(function()
    local openKey = CES_KeyHash(Config.Keys.Open)
    local mouseKey = CES_KeyHash(Config.Keys.MouseMode)
    local nextRepeat = {}

    while true do
        if openKey and not Menu.prompting and not Menu.focus
            and (IsControlJustReleased(0, openKey) or IsDisabledControlJustReleased(0, openKey)) then
            Menu.Toggle()
        end

        if Menu.open and not Menu.focus and not Menu.prompting then
            for _, h in pairs(NAV) do DisableControlAction(0, h, true) end
            if mouseKey then
                DisableControlAction(0, mouseKey, true)
                if IsDisabledControlJustReleased(0, mouseKey) then Menu.SetFocus(true) end
            end
            local now = GetGameTimer()
            for dir, h in pairs(NAV) do
                if IsDisabledControlJustPressed(0, h) then
                    SendNUIMessage({ action = 'nav', dir = dir })
                    nextRepeat[dir] = now + 380
                elseif REPEATS[dir] and IsDisabledControlPressed(0, h) then
                    if nextRepeat[dir] and now >= nextRepeat[dir] then
                        SendNUIMessage({ action = 'nav', dir = dir })
                        nextRepeat[dir] = now + 65
                    end
                end
            end
            Wait(0)
        else
            Wait(0)
        end
    end
end)

if Config.Commands.Open then
    RegisterCommand(Config.Commands.Open, function() Menu.Toggle() end, false)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and Menu.open then
        SetNuiFocus(false, false)
    end
end)
