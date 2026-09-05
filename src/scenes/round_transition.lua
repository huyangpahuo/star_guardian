-- Round transition overlay: announces the cleared round and the next one.
-- Stars/particles keep drifting via world.updateAmbient for continuity.
local round_transition = {name = "round_transition"}

function round_transition.update(ctx, f, dt)
    ctx.world.updateAmbient(dt)
end

function round_transition.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx, cy = w / 2, h / 2
    local layout = f.layout
    local i18n = ctx.i18n
    local session = ctx.session

    ctx.widgets.backdrop(w, h, ctx.time * 0.55, 0.72)

    local fs = m.title
    ctx.widgets.centerText(i18n.t("round_complete"), cx, cy - fs * 3, fs * 0.7, {0.3, 0.9, 0.5}, ctx.assets)
    ctx.widgets.centerText(i18n.t("round") .. " " .. (session.roundNum - 1), cx, cy - fs * 1.8, fs, C.text, ctx.assets)

    local nextCfg = ctx.rounds.getConfig(session.roundNum)
    ctx.widgets.centerText(i18n.t("next_round") .. ": " .. i18n.t(nextCfg.nameKey), cx, cy - fs * 0.3, fs * 0.55, {0.6, 0.8, 1}, ctx.assets)
    ctx.widgets.centerText(i18n.t(nextCfg.descKey), cx, cy + fs * 0.5, fs * 0.4, {0.7, 0.75, 0.85}, ctx.assets)
    ctx.widgets.centerText(i18n.t("score") .. ": " .. session.score, cx, cy + fs * 1.3, fs * 0.45, C.warn, ctx.assets)

    local btnW = math.min(240, w * 0.42)
    local btnH = 52
    ctx.widgets.button(ctx, layout, "continue", i18n.t("continue"), cx - btnW / 2, cy + fs * 2.2, btnW, btnH, {color = C.success})

    if math.sin(ctx.time * 3) > 0 then
        local tap = ctx.isMobile and i18n.t("continue_tap") or i18n.t("continue_hint")
        ctx.widgets.centerText(tap, cx, cy + fs * 2.2 + btnH + 15, fs * 0.3, {1, 1, 1, 0.6}, ctx.assets)
    end
end

function round_transition.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "continue" then
        ctx.audio.play("click")
        ctx.router:pop()
    end
end

function round_transition.keypressed(ctx, f, key)
    if key == "return" or key == "kpenter" or key == "space" or key == "escape" then
        ctx.audio.play("click")
        ctx.router:pop()
    end
end

return round_transition
