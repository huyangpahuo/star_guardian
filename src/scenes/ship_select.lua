-- Ship select overlay: browse the catalog with arrows/keys, inspect stats,
-- confirm the choice (persisted immediately).
local shipEntity = require("src.game.entities.player")

local ship_select = {name = "ship_select"}

function ship_select.enter(ctx, f)
    f.index = ctx.ships.indexOf(ctx.ships.getCurrentId())
    f.offset = 0
end

local function cycle(ctx, f, dir)
    local order = ctx.ships.getOrder()
    f.index = ((f.index - 1 + dir) % #order) + 1
    f.offset = dir * 80
    ctx.audio.play("click")
end

local function confirm(ctx, f)
    local order = ctx.ships.getOrder()
    local id = order[f.index]
    ctx.ships.select(id)
    ctx.save.set("ship", id)
    ctx.audio.play("click")
    ctx.router:gotoScene("menu")
end

function ship_select.update(ctx, f, dt)
    f.offset = ctx.utils.lerp(f.offset, 0, dt * 8)
end

function ship_select.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx, cy = w / 2, h / 2
    local layout = f.layout
    local i18n = ctx.i18n

    ctx.widgets.backdrop(w, h, ctx.time * 0.8, 0.55)

    local titleSize = m.heading
    ctx.widgets.centerText(i18n.t("ship_select"), cx, h * 0.06, titleSize, C.accent, ctx.assets)

    local order = ctx.ships.getOrder()
    local cfg = ctx.ships.getTypes()[order[f.index]]
    local arrowSize = math.min(w, h) * 0.06
    local arrowY = cy - arrowSize
    local leftX = cx - w * 0.35
    local rightX = cx + w * 0.35

    love.graphics.setColor(0.4, 0.7, 1, 0.6)
    ctx.assets.setFont(math.floor(arrowSize * 1.5))
    love.graphics.print("◀", leftX - love.graphics.getFont():getWidth("◀") / 2, arrowY)
    love.graphics.print("▶", rightX - love.graphics.getFont():getWidth("▶") / 2, arrowY)
    layout.left_arrow = {kind = "circle", cx = leftX, cy = arrowY + arrowSize / 2, r = arrowSize}
    layout.right_arrow = {kind = "circle", cx = rightX, cy = arrowY + arrowSize / 2, r = arrowSize}

    local size = math.min(w, h) * 0.075
    local previewX = cx + f.offset
    local previewY = cy - titleSize * 0.45 + math.sin(ctx.time * 2) * 6
    shipEntity.draw(shipEntity.preview(cfg, previewX, previewY, size))

    ctx.widgets.centerText(i18n.t(cfg.nameKey), cx, previewY + size * 0.6, titleSize * 0.5, C.text, ctx.assets)
    ctx.widgets.centerText(i18n.t(cfg.skillKey), cx, previewY + size * 0.6 + titleSize * 0.62, titleSize * 0.3, {0.7, 0.85, 1}, ctx.assets)

    local barW = math.min(340, w * 0.55)
    local barH = 12
    local barX = cx - barW / 2
    local barY = previewY + size * 0.6 + titleSize * 1.3
    local gap = 34
    ctx.widgets.statBar(barX, barY, barW, barH, i18n.t("stats_speed"), cfg.stats.speed, {0.2, 0.8, 1}, ctx.assets)
    ctx.widgets.statBar(barX, barY + gap, barW, barH, i18n.t("stats_firepower"), cfg.stats.firepower, {1, 0.4, 0.2}, ctx.assets)
    ctx.widgets.statBar(barX, barY + gap * 2, barW, barH, i18n.t("stats_hp"), cfg.stats.hp, {0.2, 0.9, 0.3}, ctx.assets)

    local btnW = math.min(220, w * 0.38)
    local btnH = 48
    local bottom = h - btnH * 2.4
    ctx.widgets.button(ctx, layout, "select", i18n.t("select"), cx - btnW / 2, bottom, btnW, btnH, {color = C.success})
    ctx.widgets.button(ctx, layout, "back", i18n.t("back"), cx - btnW / 2, bottom + btnH * 1.35, btnW, btnH, {color = C.neutral})
end

function ship_select.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "left_arrow" then cycle(ctx, f, -1)
    elseif id == "right_arrow" then cycle(ctx, f, 1)
    elseif id == "select" then confirm(ctx, f)
    elseif id == "back" then ctx.audio.play("click"); ctx.router:gotoScene("menu") end
end

function ship_select.keypressed(ctx, f, key)
    if key == "left" or key == "a" then cycle(ctx, f, -1)
    elseif key == "right" or key == "d" then cycle(ctx, f, 1)
    elseif key == "return" or key == "kpenter" then confirm(ctx, f)
    elseif key == "escape" then ctx.audio.play("click"); ctx.router:gotoScene("menu") end
end

return ship_select
