-- Language overlay: pick a language, highlight the active one, persist
-- immediately. Popping returns to wherever it was opened from.
local language = {name = "language"}

function language.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx = w / 2
    local layout = f.layout
    local i18n = ctx.i18n

    ctx.widgets.backdrop(w, h, ctx.time * 0.7, 0.34)

    local titleSize = m.heading
    ctx.widgets.centerText(i18n.t("language_menu"), cx, h * 0.18, titleSize, {0.4, 0.85, 1}, ctx.assets)

    local btnW = math.min(300, w * 0.45)
    local btnH = 54
    local startY = h * 0.38
    local i = 0
    for _, code in ipairs(i18n.getLangs()) do
        local y = startY + i * (btnH + 16)
        ctx.widgets.button(ctx, layout, "lang_" .. code, i18n.getName(code), cx - btnW / 2, y, btnW, btnH,
            {color = code == i18n.lang and C.success or C.secondary})
        i = i + 1
    end

    ctx.widgets.button(ctx, layout, "back", i18n.t("back"), cx - btnW / 2, startY + i * (btnH + 16) + 24, btnW, btnH,
        {color = C.neutral})
end

function language.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if not id then return end
    ctx.audio.play("click")
    if id == "back" then
        ctx.router:pop()
    elseif id:sub(1, 5) == "lang_" then
        ctx.setLanguage(id:sub(6))
    end
end

function language.keypressed(ctx, f, key)
    if key == "escape" then
        ctx.audio.play("click")
        ctx.router:pop()
    end
end

return language
