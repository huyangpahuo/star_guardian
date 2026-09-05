-- Settings overlay: live volume sliders for master / sfx / music.
-- Slider geometry comes from the same layout pass that hit-tests it, and
-- the profile is written once on close rather than on every mouse move.
local settings = {name = "settings"}

function settings.enter(ctx, f)
    local audio = ctx.audio
    f.sliders = {
        master = {value = audio.masterVol},
        sfx = {value = audio.sfxVol},
        music = {value = audio.musicVol},
    }
    f.dragging = nil
end

local function applyVolume(ctx, id, value)
    local audio = ctx.audio
    if id == "master" then audio.setMasterVolume(value)
    elseif id == "sfx" then audio.setSfxVolume(value)
    elseif id == "music" then audio.setMusicVolume(value) end
end

local function close(ctx, f)
    ctx.save.data.audio = {
        master = ctx.audio.masterVol,
        sfx = ctx.audio.sfxVol,
        music = ctx.audio.musicVol,
    }
    ctx.save.write()
    ctx.router:gotoScene("menu")
end

function settings.draw(ctx, f)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx = w / 2
    local layout = f.layout
    local i18n = ctx.i18n

    ctx.widgets.backdrop(w, h, ctx.time * 0.6, 0.38)

    local titleSize = m.heading
    ctx.widgets.centerText(i18n.t("settings"), cx, h * 0.07, titleSize, C.accent, ctx.assets)

    local sliderW = math.min(460, w * 0.65)
    local sliderH = 30
    local sliderX = cx - sliderW / 2
    local startY = math.max(h * 0.30, h / 2 - titleSize * 1.35)
    local gap = math.max(96, sliderH * 3.2)

    ctx.widgets.slider(ctx, layout, "master", sliderX, startY, sliderW, sliderH, i18n.t("master_vol"), f.sliders.master.value)
    ctx.widgets.slider(ctx, layout, "sfx", sliderX, startY + gap, sliderW, sliderH, i18n.t("sfx_vol"), f.sliders.sfx.value)
    ctx.widgets.slider(ctx, layout, "music", sliderX, startY + gap * 2, sliderW, sliderH, i18n.t("music_vol"), f.sliders.music.value)

    local btnW = math.min(220, w * 0.38)
    local btnH = 48
    ctx.widgets.button(ctx, layout, "back", i18n.t("back"), cx - btnW / 2, h - btnH * 2, btnW, btnH, {color = C.neutral})
end

function settings.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "back" then
        ctx.audio.play("click")
        close(ctx, f)
    elseif f.sliders[id] then
        f.dragging = id
        local value = ctx.widgets.sliderRatio(f.layout[id], x)
        f.sliders[id].value = value
        applyVolume(ctx, id, value)
    end
end

function settings.pointermoved(ctx, f, x, y)
    if not f.dragging then return end
    local hit = f.layout[f.dragging]
    if not hit then return end
    local value = ctx.widgets.sliderRatio(hit, x)
    f.sliders[f.dragging].value = value
    applyVolume(ctx, f.dragging, value)
end

function settings.pointerreleased(ctx, f)
    f.dragging = nil
end

function settings.keypressed(ctx, f, key)
    if key == "escape" then close(ctx, f) end
end

return settings
