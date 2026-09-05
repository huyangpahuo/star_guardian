-- Game over screen: final score, new-record banner, restart / menu.
local runflow = require("src.game.runflow")

local gameover = {name = "gameover"}

function gameover.update(ctx, f, dt)
    ctx.world.updateAmbient(dt)
end

function gameover.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx, cy = w / 2, h / 2
    local layout = f.layout
    local i18n = ctx.i18n
    local session = ctx.session

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local fs = math.min(w, h) * 0.09
    ctx.widgets.centerText(i18n.t("game_over"), cx, cy - fs * 2.5, fs, {1, 0.3, 0.2}, ctx.assets)
    ctx.widgets.centerText(i18n.t("final_score") .. ": " .. session.score, cx, cy - fs * 1.2, fs * 0.5, C.text, ctx.assets)
    if session.score >= session.highscore and session.score > 0 then
        ctx.widgets.centerText(i18n.t("new_record"), cx, cy - fs * 0.4, fs * 0.4, C.warn, ctx.assets)
    end
    ctx.widgets.centerText(i18n.t("highscore") .. ": " .. ctx.save.data.highscore, cx, cy + fs * 0.3, fs * 0.35, C.dim, ctx.assets)

    local btnW = math.min(260, w * 0.44)
    local btnH = m.btnH
    local startY = cy + fs * 1.2
    ctx.widgets.button(ctx, layout, "restart", i18n.t("start"), cx - btnW / 2, startY, btnW, btnH, {color = C.primary})
    ctx.widgets.button(ctx, layout, "menu", i18n.t("back"), cx - btnW / 2, startY + btnH * 1.5, btnW, btnH, {color = C.neutral})

    if math.sin(love.timer.getTime() * 3) > 0 then
        local rt = ctx.isMobile and i18n.t("restart_tap") or i18n.t("restart_hint")
        ctx.widgets.centerText(rt, cx, startY + btnH * 3.0, fs * 0.3, C.warn, ctx.assets)
    end
end

function gameover.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "restart" then
        ctx.audio.play("click")
        runflow.start(ctx)
    elseif id == "menu" then
        ctx.audio.play("click")
        ctx.save.write()
        ctx.router:gotoScene("menu")
    end
end

function gameover.keypressed(ctx, f, key)
    if key == "return" or key == "kpenter" then
        ctx.audio.play("click")
        runflow.start(ctx)
    elseif key == "escape" then
        ctx.audio.play("click")
        ctx.save.write()
        ctx.router:gotoScene("menu")
    end
end

return gameover
