'use strict';

const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ces_menu';
const $ = (id) => document.getElementById(id);

function post(name, data = {}) {
    return fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then((r) => r.json()).catch(() => null);
}

const escapeHtml = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

// printf-lite for slider formats: %d %02d %.2f with any surrounding text
function fmt(format, v) {
    if (!format) return Number.isInteger(v) ? String(v) : Number(v).toFixed(2);
    return format.replace(/%(0?)(\d*)(?:\.(\d+))?([df])/, (_, zero, width, prec, type) => {
        let s = type === 'd' ? String(Math.round(v)) : Number(v).toFixed(prec ? +prec : 6);
        if (width) s = s.padStart(+width, zero ? '0' : ' ');
        return s;
    });
}

const decimals = (step) => ((String(step).split('.')[1]) || '').length;

// ───────────────────────── State ─────────────────────────
const state = {
    open: false,
    focus: false,
    menu: null,         // { key, title, items, empty, depth }
    view: [],           // items currently shown (filtered)
    sel: 0,             // index into view
    memo: {},           // menuKey -> selected item id
    filter: '',
    visible: 10,
    mouseKey: 'LALT',
    loading: false,
};

const selectable = (it) => it && it.type !== 'separator';

function computeView() {
    const items = state.menu ? state.menu.items : [];
    const f = state.filter.trim().toLowerCase();
    state.view = f
        ? items.filter((it) => selectable(it) && String(it.label).toLowerCase().includes(f))
        : items.slice();
}

function firstSelectable(from = 0, dir = 1) {
    const n = state.view.length;
    if (!n) return 0;
    for (let i = 0; i < n; i++) {
        const idx = (((from + i * dir) % n) + n) % n;
        if (selectable(state.view[idx])) return idx;
    }
    return 0;
}

function restoreSelection() {
    const key = state.menu && state.menu.key;
    const id = key ? state.memo[key] : null;
    const idx = id ? state.view.findIndex((it) => it.id === id) : -1;
    state.sel = idx >= 0 ? idx : firstSelectable(0, 1);
}

let hoverTimer = null;
function hoverNotify() {
    clearTimeout(hoverTimer);
    const it = state.view[state.sel];
    if (!it || !it.hover || it.locked || !state.menu) return;
    const key = state.menu.key;
    hoverTimer = setTimeout(() => post('hover', { menu: key, id: it.id }), 110);
}

function remember() {
    const it = state.view[state.sel];
    if (state.menu && it) state.memo[state.menu.key] = it.id;
}

// ───────────────────────── Rendering ─────────────────────────
function rightHtml(it) {
    switch (it.type) {
        case 'checkbox':
            return `<span class="box ${it.checked ? 'on' : ''}"></span>`;
        case 'submenu':
            return `${it.right ? `<span class="right">${escapeHtml(it.right)}</span>` : ''}<span class="chev">›</span>`;
        case 'list': {
            const opts = it.options || [];
            const label = opts[(it.index || 1) - 1] ?? '';
            return `<span class="list"><span class="arrow" data-dir="-1">◀</span><span>${escapeHtml(label)}</span><span class="arrow" data-dir="1">▶</span></span>`;
        }
        case 'slider': {
            const min = it.min ?? 0, max = it.max ?? 1;
            const pct = max > min ? ((it.value - min) / (max - min)) * 100 : 0;
            return `<span class="slider"><span class="arrow" data-dir="-1">◀</span><span class="track"><span class="fill" style="width:${pct.toFixed(1)}%"></span></span><span class="val">${escapeHtml(fmt(it.format, it.value))}</span><span class="arrow" data-dir="1">▶</span></span>`;
        }
        default:
            return it.right ? `<span class="right">${escapeHtml(it.right)}</span>` : '';
    }
}

function render() {
    const menu = state.menu;
    const list = $('items');
    if (!menu) { list.innerHTML = ''; return; }

    $('crumb').textContent = state.loading ? `${menu.title} · loading…` : menu.title;

    const view = state.view;
    const selectables = view.filter(selectable);
    const pos = selectables.indexOf(view[state.sel]);
    $('counter').textContent = selectables.length ? `${pos + 1} / ${selectables.length}` : '';

    if (!view.length) {
        list.innerHTML = `<li class="empty">${escapeHtml(state.filter ? 'No matches.' : (menu.empty || 'Nothing here.'))}</li>`;
        $('desc').classList.add('hidden');
        $('scrollhint').classList.add('hidden');
        return;
    }

    const max = state.visible;
    let start = 0;
    if (view.length > max) {
        start = Math.min(Math.max(0, state.sel - Math.floor(max / 2)), view.length - max);
    }
    const end = Math.min(view.length, start + max);

    let html = '';
    for (let i = start; i < end; i++) {
        const it = view[i];
        if (it.type === 'separator') {
            html += `<li class="separator ${it.label ? '' : 'blank'}" data-i="${i}">${escapeHtml(it.label)}</li>`;
            continue;
        }
        const cls = [i === state.sel ? 'selected' : '', it.disabled ? 'disabled' : '', it.locked ? 'locked' : ''].join(' ');
        const right = it.locked ? '<span class="right"></span>' : rightHtml(it);
        html += `<li class="${cls}" data-i="${i}"><span class="label">${escapeHtml(it.label)}</span>${right}</li>`;
    }
    list.innerHTML = html;
    $('scrollhint').classList.toggle('hidden', end >= view.length);

    const cur = view[state.sel];
    const desc = cur && (cur.locked ? 'You do not have permission for this option.' : cur.desc);
    $('desc').classList.toggle('hidden', !desc);
    $('desc').textContent = desc || '';

    $('modebar').innerHTML = state.focus
        ? '<span>Click · Scroll · Right-click back</span><span>Type to search · <kbd>Esc</kbd> exit</span>'
        : `<span>↑↓ Move · ←→ Change · Enter · ⌫ Back</span><span><kbd>${escapeHtml(state.mouseKey || '')}</kbd> Mouse</span>`;
}

// ───────────────────────── Actions ─────────────────────────
function move(dir) {
    if (!state.view.length) return;
    state.sel = firstSelectable(state.sel + dir, dir);
    remember();
    render();
    hoverNotify();
}

function interact(it, kind, value) {
    post('interact', { menu: state.menu.key, id: it.id, kind, value });
}

function activate() {
    const it = state.view[state.sel];
    if (!it || !selectable(it)) return;
    if (it.locked) { toast({ message: 'You do not have permission for this option.', kind: 'error' }); return; }
    if (it.disabled) return;
    remember();
    if (it.type === 'checkbox') { it.checked = !it.checked; render(); }
    if (it.type === 'list') return interact(it, 'select', it.index || 1);
    if (it.type === 'slider') return interact(it, 'select', it.value);
    interact(it, 'select');
}

const sliderTimers = {};
function change(dir) {
    const it = state.view[state.sel];
    if (!it || it.locked || it.disabled) return;
    if (it.type === 'list') {
        const n = (it.options || []).length;
        if (!n) return;
        it.index = ((((it.index || 1) - 1 + dir) % n) + n) % n + 1;
        render();
        interact(it, 'change', it.index);
    } else if (it.type === 'slider') {
        const step = it.step || 1;
        let v = Math.min(it.max, Math.max(it.min, (it.value ?? it.min) + dir * step));
        v = Number(v.toFixed(decimals(step)));
        if (v === it.value) return;
        it.value = v;
        render();
        clearTimeout(sliderTimers[it.id]);
        sliderTimers[it.id] = setTimeout(() => interact(it, 'change', it.value), 120);
    } else if (it.type === 'checkbox' && ((dir > 0) !== !!it.checked)) {
        activate();
    }
}

function back() {
    if (state.filter) { setFilter(''); return; }
    post('back');
}

function setFilter(v) {
    state.filter = v;
    $('searchInput').value = v;
    computeView();
    state.sel = firstSelectable(0, 1);
    render();
    hoverNotify();
}

function setFocus(v) {
    state.focus = v;
    document.body.classList.toggle('focus', v);
    $('search').classList.toggle('hidden', !v);
    if (v) {
        setTimeout(() => $('searchInput').focus(), 0);
    } else {
        $('searchInput').blur();
        if (state.filter) setFilter('');
    }
    render();
}

// ───────────────────────── Toasts / overlays ─────────────────────────
function toast({ message, kind = 'info', title, duration }) {
    const wrap = $('toasts');
    while (wrap.children.length >= 5) wrap.firstChild.remove();
    const el = document.createElement('div');
    el.className = `toast ${kind}`;
    const defTitle = { success: 'Done', error: 'Error', warning: 'Notice', info: '' }[kind] || '';
    const t = title || defTitle;
    el.innerHTML = `${t ? `<div class="t-title">${escapeHtml(t)}</div>` : ''}<div>${escapeHtml(message)}</div>`;
    wrap.appendChild(el);
    setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 250); }, duration || 4000);
}

let announceTimer;
function announce(msg, from) {
    const el = $('announce');
    el.querySelector('.announce-from').textContent = from ? `Announcement · ${from}` : 'Announcement';
    el.querySelector('.announce-text').textContent = msg;
    el.classList.remove('hidden');
    clearTimeout(announceTimer);
    announceTimer = setTimeout(() => el.classList.add('hidden'), 9000);
}

const pills = {};
function setPill(id, html) {
    if (!html) { if (pills[id]) { pills[id].remove(); delete pills[id]; } return; }
    if (!pills[id]) { pills[id] = document.createElement('div'); pills[id].className = 'pill'; $('status').appendChild(pills[id]); }
    pills[id].innerHTML = html;
}

function copy(text) {
    const ta = $('clipboard');
    ta.value = text;
    ta.select();
    try { document.execCommand('copy'); } catch (e) { /* ignore */ }
    ta.blur();
}

// ───────────────────────── Prompt ─────────────────────────
let promptId = null;
function openPrompt(d) {
    promptId = d.id;
    document.querySelector('.prompt-title').textContent = d.title || 'Input';
    const input = $('promptInput');
    input.value = d.value || '';
    input.placeholder = d.placeholder || '';
    input.maxLength = d.maxLength || 250;
    $('prompt').classList.remove('hidden');
    setTimeout(() => { input.focus(); input.select(); }, 30);
}
function closePrompt(value) {
    if (promptId === null) return;
    const id = promptId;
    promptId = null;
    $('prompt').classList.add('hidden');
    $('promptInput').blur();
    post('prompt', { id, value });
}
$('promptOk').addEventListener('click', () => closePrompt($('promptInput').value));
$('promptCancel').addEventListener('click', () => closePrompt(null));

// ───────────────────────── Settings ─────────────────────────
function applySettings(d) {
    const s = d.settings || {};
    if (d.title) $('title').textContent = d.title;
    if (d.subtitle !== undefined) $('brand').textContent = d.subtitle;
    if (d.mouseKey !== undefined) state.mouseKey = d.mouseKey;
    document.body.dataset.theme = s.theme || 'western';
    const root = $('root');
    root.className = s.align === 'left' ? 'align-left' : 'align-right';
    root.style.setProperty('--scale', s.scale || 1);
    state.visible = Math.max(4, Math.round(s.visibleItems || 10));
    render();
}

// ───────────────────────── Messages from Lua ─────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data || {};
    switch (d.action) {
        case 'open':
            state.open = true;
            $('menu').classList.remove('hidden');
            break;
        case 'close':
            state.open = false;
            $('menu').classList.add('hidden');
            setFocus(false);
            break;
        case 'loading':
            state.loading = true;
            if (state.menu) { state.menu = { ...state.menu, title: d.title || state.menu.title, items: [] }; computeView(); render(); }
            break;
        case 'menu': {
            const changed = !state.menu || state.menu.key !== d.menu.key;
            if (changed) remember();
            state.loading = false;
            state.menu = d.menu;
            if (changed && state.filter) { state.filter = ''; $('searchInput').value = ''; }
            computeView();
            restoreSelection();
            render();
            if (changed) hoverNotify();
            break;
        }
        case 'nav':
            if (!state.open || promptId !== null) break;
            if (d.dir === 'up') move(-1);
            else if (d.dir === 'down') move(1);
            else if (d.dir === 'left') change(-1);
            else if (d.dir === 'right') change(1);
            else if (d.dir === 'select') activate();
            else if (d.dir === 'back') back();
            break;
        case 'focus':
            setFocus(!!d.value);
            break;
        case 'settings':
            applySettings(d);
            break;
        case 'notify':
            toast(d);
            break;
        case 'announce':
            announce(d.message, d.from);
            break;
        case 'prompt':
            openPrompt(d);
            break;
        case 'copy':
            copy(d.text);
            break;
        case 'coords':
            if (d.hide) { $('coords').classList.add('hidden'); break; }
            $('coords').classList.remove('hidden');
            $('coords').innerHTML =
                `<span>X</span>${d.x.toFixed(2)}<i class="sep">|</i><span>Y</span>${d.y.toFixed(2)}<i class="sep">|</i><span>Z</span>${d.z.toFixed(2)}<i class="sep">|</i><span>H</span>${d.h.toFixed(1)}`;
            break;
        case 'noclip':
            setPill('noclip', d.value ? `NOCLIP · speed <b>${d.speed}</b>` : null);
            break;
        case 'spectate':
            setPill('spectate', d.value ? `SPECTATING · <b>${escapeHtml(d.name)}</b>` : null);
            break;
    }
});

// ───────────────────────── Mouse / keyboard (focus mode) ─────────────────────────
$('items').addEventListener('click', (e) => {
    if (!state.focus) return;
    const li = e.target.closest('li[data-i]');
    if (!li) return;
    const i = +li.dataset.i;
    if (!selectable(state.view[i])) return;
    const moved = state.sel !== i;
    state.sel = i;
    remember();
    if (moved) hoverNotify();
    const arrow = e.target.closest('.arrow');
    if (arrow) { change(+arrow.dataset.dir); return; }
    render();
    activate();
});

$('items').addEventListener('contextmenu', (e) => { e.preventDefault(); if (state.focus) back(); });

$('menu').addEventListener('wheel', (e) => {
    if (!state.focus) return;
    e.preventDefault();
    move(e.deltaY > 0 ? 1 : -1);
}, { passive: false });

$('searchInput').addEventListener('input', (e) => setFilter(e.target.value));

document.addEventListener('keydown', (e) => {
    if (promptId !== null) {
        if (e.key === 'Enter') { e.preventDefault(); closePrompt($('promptInput').value); }
        else if (e.key === 'Escape') { e.preventDefault(); closePrompt(null); }
        return;
    }
    if (!state.focus) return;
    const searching = document.activeElement === $('searchInput');
    switch (e.key) {
        case 'ArrowUp': e.preventDefault(); move(-1); break;
        case 'ArrowDown': e.preventDefault(); move(1); break;
        case 'ArrowLeft': if (!searching || !state.filter) { e.preventDefault(); change(-1); } break;
        case 'ArrowRight': if (!searching || !state.filter) { e.preventDefault(); change(1); } break;
        case 'Enter': e.preventDefault(); activate(); break;
        case 'Backspace':
            if (!state.filter) { e.preventDefault(); post('back'); }
            break;
        case 'Escape':
            e.preventDefault();
            if (state.filter) setFilter('');
            else post('exitFocus');
            break;
        case 'Alt':
            e.preventDefault();
            post('exitFocus');
            break;
        default:
            if (!searching && e.key.length === 1) $('searchInput').focus();
    }
});

post('ready');
