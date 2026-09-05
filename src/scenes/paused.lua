-- Pause overlay: freezes gameplay (router only updates the top scene),
-- offers resume and a direct exit back to the menu.
local paused = {name = "paused"}

local function resume(ctx)
    ctx.audio.play("click")
    ctx.router:pop()
end

local function exitToMenu(ctx)
    ctx.audio.play("click")
    ctx.session.runActive = false
    ctx.save.write()
    ctx.router:gotoScene("menu")
end

function paused.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx = w / 2
    local layout = f.layout
    local i18n = ctx.i18n

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local fs = m.title
    ctx.widgets.centerText(i18n.t("paused"), cx, h / 2 - fs * 1.6, fs, C.text, ctx.assets)

    local btnW = math.min(260, w * 0.44)
    local btnH = m.btnH
    local startY = h / 2 - btnH * 0.4
    ctx.widgets.button(ctx, layout, "resume", i18n.t("resume"), cx - btnW / 2, startY, btnW, btnH, {color = C.success})
    ctx.widgets.button(ctx, layout, "exit", i18n.t("exit_to_menu"), cx - btnW / 2, startY + btnH * 1.5, btnW, btnH, {color = C.danger})

    local hint = ctx.isMobile and i18n.t("continue_tap") or i18n.t("continue_hint")
    ctx.widgets.centerText(hint, cx, startY + btnH * 3.0, fs * 0.35, C.dim, ctx.assets)
end

function paused.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "resume" then resume(ctx)
    elseif id == "exit" then exitToMenu(ctx) end
end

function paused.keypressed(ctx, f, key)
    if key == "p" or key == "escape" then resume(ctx) end
end

return paused
