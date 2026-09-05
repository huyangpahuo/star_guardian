-- Exit confirmation overlay: can be pushed from any scene, "No" simply
-- pops back to wherever the user was (menu, paused, mid-run, ...).
local exit_prompt = {name = "exit_prompt"}

local function confirmYes(ctx)
    ctx.audio.play("click")
    ctx.session.runActive = false
    ctx.save.write()
    ctx.router:gotoScene("menu")
end

local function confirmNo(ctx)
    ctx.audio.play("click")
    ctx.router:pop()
end

function exit_prompt.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx, cy = w / 2, h / 2
    local layout = f.layout
    local i18n = ctx.i18n

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local fs = math.min(w, h) * 0.055
    ctx.widgets.centerText(i18n.t("exit_title"), cx, cy - fs * 2.2, fs, C.text, ctx.assets)
    ctx.widgets.centerText(i18n.t("exit_msg"), cx, cy - fs * 1.1, fs * 0.6, {0.8, 0.85, 1}, ctx.assets)

    local btnW = math.min(240, w * 0.35)
    local btnH = 50
    ctx.widgets.button(ctx, layout, "yes", i18n.t("exit_yes"), cx - btnW / 2, cy + 20, btnW, btnH, {color = C.danger})
    ctx.widgets.button(ctx, layout, "no", i18n.t("exit_no"), cx - btnW / 2, cy + 90, btnW, btnH, {color = C.secondary})
end

function exit_prompt.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "yes" then confirmYes(ctx)
    elseif id == "no" then confirmNo(ctx) end
end

function exit_prompt.keypressed(ctx, f, key)
    if key == "return" or key == "kpenter" then confirmYes(ctx)
    elseif key == "escape" then confirmNo(ctx) end
end

return exit_prompt
