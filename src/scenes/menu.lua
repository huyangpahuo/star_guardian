-- Main menu: left column holds the action buttons (including quit),
-- right column shows the ship preview, a translated game intro and the
-- author credit. Ship select / settings / language open as their own
-- full screens instead of floating over this one.
local runflow = require("src.game.runflow")
local shipEntity = require("src.game.entities.player")

local menu = {name = "menu"}

local function startRun(ctx)
    ctx.audio.play("click")
    runflow.start(ctx)
end

-- Right column: floating ship preview, translated intro lines, author.
-- Intro text wraps inside the column width so long translations
-- (e.g. English) can never spill past the window edge.
local function drawIntro(ctx, cx, colW)
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)

    -- floating preview of the selected ship (throwaway entity, no world access)
    local cfg = ctx.ships.getCurrent()
    local size = math.min(w, h) * 0.055
    local py = h * 0.24 + math.sin(ctx.time * 2) * 8
    shipEntity.draw(shipEntity.preview(cfg, cx, py, size))

    local maxW = colW * 0.92
    local body = math.max(14, m.body * 0.85)

    local lines = {}
    for i = 1, 4 do
        lines[#lines + 1] = ctx.i18n.t("intro_" .. i)
    end
    ctx.assets.setFont(math.floor(body))
    love.graphics.setColor(0.75, 0.85, 1)
    love.graphics.printf(table.concat(lines, "\n"), cx - maxW / 2, h * 0.40, maxW, "center")

    -- author credit: label is translated, the name itself stays as-is
    ctx.assets.setFont(math.floor(body * 1.1))
    love.graphics.setColor(ctx.theme.colors.accent[1], ctx.theme.colors.accent[2], ctx.theme.colors.accent[3])
    love.graphics.printf(ctx.i18n.t("author_label") .. ": 胡杨怕火", cx - maxW / 2, h - h * 0.10, maxW, "center")
end

function menu.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local layout = f.layout
    local i18n = ctx.i18n

    ctx.widgets.backdrop(w, h, ctx.time, 0.38)

    -- left column geometry
    local colW = w * 0.42
    local leftX = math.max(m.margin * 2, w * 0.06)
    local btnW = math.min(300, colW * 0.78)
    local btnH = math.min(52, h * 0.075)
    local gap = btnH * 0.5

    -- subtle divider between the two columns
    love.graphics.setColor(1, 1, 1, 0.10)
    love.graphics.line(leftX + colW + w * 0.02, h * 0.14, leftX + colW + w * 0.02, h * 0.86)

    -- title block
    local titleSize = math.min(m.title * 0.85, colW / 5.2)
    ctx.assets.setFont(math.floor(titleSize))
    love.graphics.setColor(C.accent[1], C.accent[2], C.accent[3])
    love.graphics.print(i18n.t("title"), leftX, h * 0.11)
    ctx.assets.setFont(math.floor(titleSize * 0.36))
    love.graphics.setColor(0.5, 0.8, 1, 0.7)
    love.graphics.print(i18n.t("subtitle"), leftX + 4, h * 0.11 + titleSize * 1.25)

    -- action buttons
    local items = {
        {id = "start",       key = "start",         color = C.primary},
        {id = "ship_select", key = "ship_select",   color = C.secondary},
        {id = "settings",    key = "settings",      color = C.secondary},
        {id = "language",    key = "language_menu", color = {0.55, 0.55, 1}},
        {id = "exit",        key = "exit_game",     color = C.danger},
    }
    local startY = h * 0.34
    for i, item in ipairs(items) do
        local y = startY + (i - 1) * (btnH + gap)
        ctx.widgets.button(ctx, layout, item.id, i18n.t(item.key), leftX, y, btnW, btnH, {color = item.color})
    end

    -- blinking start hint under the buttons
    local hintY = startY + #items * (btnH + gap) + btnH * 0.15
    if math.sin(ctx.time * 4) > 0 then
        local hint = ctx.isMobile and i18n.t("tap_hint") or i18n.t("start_hint")
        ctx.assets.setFont(math.floor(btnH * 0.42))
        love.graphics.setColor(C.warn[1], C.warn[2], C.warn[3])
        love.graphics.print(hint, leftX + btnW / 2 - love.graphics.getFont():getWidth(hint) / 2, hintY)
    end

    -- right column
    local rightCx = leftX + colW + w * 0.02 + (w - leftX - colW - w * 0.02) / 2
    drawIntro(ctx, rightCx, w - leftX - colW - w * 0.04)
end

function menu.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "start" then
        startRun(ctx)
    elseif id == "ship_select" then
        ctx.audio.play("click")
        ctx.router:gotoScene("ship_select")
    elseif id == "settings" then
        ctx.audio.play("click")
        ctx.router:gotoScene("settings")
    elseif id == "language" then
        ctx.audio.play("click")
        ctx.router:gotoScene("language")
    elseif id == "exit" then
        ctx.audio.play("click")
        love.event.quit()
    end
end

function menu.keypressed(ctx, f, key)
    -- Esc intentionally does nothing on the main menu now
    if key == "return" or key == "kpenter" then
        startRun(ctx)
    elseif key == "l" then
        ctx.audio.play("click")
        ctx.router:gotoScene("language")
    end
end

return menu
