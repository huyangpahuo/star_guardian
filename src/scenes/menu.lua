-- Main menu: start a run, open overlays (ship select / settings / language),
-- quick language switch, exit confirmation.
local runflow = require("src.game.runflow")
local shipEntity = require("src.game.entities.player")

local menu = {name = "menu"}

local function startRun(ctx)
    ctx.audio.play("click")
    runflow.start(ctx)
end

-- Quick language switcher shown on the menu itself.
local function drawLangSwitch(ctx, layout, cx, y)
    local langs = {{"en", "EN"}, {"zh_CN", "中文"}, {"ja", "日本語"}}
    local bs = math.min(ctx.w, ctx.h) * 0.035
    local gap = bs * 3
    local startX = cx - (#langs - 1) * gap / 2
    local g = love.graphics
    for i, l in ipairs(langs) do
        local bx = startX + (i - 1) * gap
        local active = ctx.i18n.lang == l[1]
        if active then
            g.setColor(0.3, 0.6, 1, 0.35)
            g.circle("fill", bx, y, bs * 0.85)
        end
        g.setColor(active and {1, 1, 1} or {0.55, 0.55, 0.62})
        ctx.assets.setFont(math.floor(bs * 0.62))
        g.print(l[2], bx - g.getFont():getWidth(l[2]) / 2, y - bs * 0.31)
        layout["lang_" .. l[1]] = {kind = "circle", cx = bx, cy = y, r = bs * 0.9}
    end
end

function menu.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx = w / 2
    local layout = f.layout
    local i18n = ctx.i18n

    ctx.widgets.backdrop(w, h, ctx.time, 0.38)

    local titleSize = m.title
    ctx.widgets.centerText(i18n.t("title"), cx, h * 0.16, titleSize, C.accent, ctx.assets)
    ctx.widgets.centerText(i18n.t("subtitle"), cx, h * 0.16 + titleSize * 1.15, titleSize * 0.42, {0.5, 0.8, 1, 0.7}, ctx.assets)

    -- floating preview of the selected ship (throwaway entity, no world access)
    local cfg = ctx.ships.getCurrent()
    local size = math.min(w, h) * 0.075
    local py = h * 0.40 + math.sin(ctx.time * 2) * 8
    shipEntity.draw(shipEntity.preview(cfg, cx, py, size))

    local btnW, btnH, gap = m.btnW, m.btnH, m.btnGap
    local startY = h * 0.52
    ctx.widgets.button(ctx, layout, "start", i18n.t("start"), cx - btnW / 2, startY, btnW, btnH, {color = C.primary})
    ctx.widgets.button(ctx, layout, "ship_select", i18n.t("ship_select"), cx - btnW / 2, startY + gap, btnW, btnH, {color = C.secondary})
    ctx.widgets.button(ctx, layout, "settings", i18n.t("settings"), cx - btnW / 2, startY + gap * 2, btnW, btnH, {color = C.secondary})
    ctx.widgets.button(ctx, layout, "language", i18n.t("language_menu"), cx - btnW / 2, startY + gap * 3, btnW, btnH, {color = {0.55, 0.55, 1}})

    if math.sin(ctx.time * 4) > 0 then
        local hint = ctx.isMobile and i18n.t("tap_hint") or i18n.t("start_hint")
        ctx.widgets.centerText(hint, cx, startY + gap * 3 + btnH + 12, titleSize * 0.28, C.warn, ctx.assets)
    end

    drawLangSwitch(ctx, layout, cx, h - math.min(w, h) * 0.07)
end

function menu.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "start" then
        startRun(ctx)
    elseif id == "ship_select" then
        ctx.audio.play("click")
        ctx.router:push("ship_select")
    elseif id == "settings" then
        ctx.audio.play("click")
        ctx.router:push("settings")
    elseif id == "language" then
        ctx.audio.play("click")
        ctx.router:push("language")
    elseif id and id:sub(1, 5) == "lang_" then
        ctx.setLanguage(id:sub(6))
        ctx.audio.play("click")
    end
end

function menu.keypressed(ctx, f, key)
    if key == "return" or key == "kpenter" then
        startRun(ctx)
    elseif key == "l" then
        ctx.audio.play("click")
        ctx.router:push("language")
    elseif key == "escape" then
        ctx.audio.play("click")
        ctx.router:push("exit_prompt")
    end
end

return menu
