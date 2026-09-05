-- Debug overlay (F1): live profile stats, input state, volume shortcuts,
-- fullscreen and language toggles. Dev-only screen; labels stay English.
local debug = {name = "debug"}

function debug.draw(ctx, f)
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local cx, cy = w / 2, h / 2
    local layout = f.layout
    local audio = ctx.audio

    ctx.widgets.backdrop(w, h, ctx.time * 0.4, 0.82)

    local panelW, panelH = m.panelW, m.panelH
    local px, py = cx - panelW / 2, cy - panelH / 2

    love.graphics.setColor(0.1, 0.14, 0.22, 0.95)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 16, 16)
    love.graphics.setColor(0.45, 0.75, 1, 0.55)
    love.graphics.rectangle("line", px, py, panelW, panelH, 16, 16)

    ctx.assets.setFont(math.floor(math.min(w, h) * 0.055))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Debug Panel", px + 28, py + 18)
    ctx.assets.setFont(math.floor(math.min(w, h) * 0.03))
    love.graphics.setColor(0.75, 0.86, 1)
    love.graphics.print("F1 close  |  Save is automatic", px + 28, py + 62)

    local left = px + 28
    local top = py + 110
    local bw = 220
    local bh = 42

    ctx.widgets.button(ctx, layout, "language", "Language: " .. ctx.i18n.lang, left, top, bw, bh, {color = {0.35, 0.55, 0.95}})
    ctx.widgets.button(ctx, layout, "fullscreen", "Fullscreen: " .. tostring(love.window.getFullscreen() and "On" or "Off"), left, top + 56, bw, bh, {color = {0.35, 0.75, 0.55}})
    ctx.widgets.button(ctx, layout, "back", "Back", left, top + 112, bw, bh, {color = {0.5, 0.5, 0.6}})
    ctx.widgets.button(ctx, layout, "master", "Master " .. math.floor(audio.masterVol * 100) .. "%", left + 250, top, bw, bh, {color = {0.4, 0.7, 1}})
    ctx.widgets.button(ctx, layout, "sfx", "SFX " .. math.floor(audio.sfxVol * 100) .. "%", left + 250, top + 56, bw, bh, {color = {0.4, 0.7, 1}})
    ctx.widgets.button(ctx, layout, "music", "Music " .. math.floor(audio.musicVol * 100) .. "%", left + 250, top + 112, bw, bh, {color = {0.4, 0.7, 1}})

    local stats = ctx.save.data.stats or {}
    ctx.assets.setFont(math.floor(math.min(w, h) * 0.028))
    love.graphics.setColor(0.9, 0.95, 1)
    local lines = {
        "Runs: " .. (stats.runs or 0),
        "Best Score: " .. (stats.bestScore or 0),
        "Total Score: " .. (stats.totalScore or 0),
        "Kills: " .. (stats.kills or 0),
        "Deaths: " .. (stats.deaths or 0),
        "Damage Taken: " .. (stats.damageTaken or 0),
        "Session Score: " .. ctx.session.score .. "  Round " .. ctx.session.roundNum,
        "Input L/R/Shoot: " .. tostring(ctx.input.actions.left) .. " / " .. tostring(ctx.input.actions.right) .. " / " .. tostring(ctx.input.actions.shoot),
    }
    for i, line in ipairs(lines) do
        love.graphics.print(line, left, top + 190 + (i - 1) * 28)
    end
end

function debug.pointerpressed(ctx, f, x, y)
    local id = ctx.widgets.hitTest(f.layout, x, y)
    if id == "language" then
        ctx.router:gotoScene("language")
    elseif id == "fullscreen" then
        ctx.toggleFullscreen()
    elseif id == "back" then
        ctx.audio.play("click")
        ctx.router:pop()
    elseif id == "master" then
        ctx.audio.setMasterVolume(ctx.audio.masterVol >= 0.95 and 0 or ctx.audio.masterVol + 0.25)
        ctx.save.data.audio.master = ctx.audio.masterVol
        ctx.save.write()
    elseif id == "sfx" then
        ctx.audio.setSfxVolume(ctx.audio.sfxVol >= 0.95 and 0 or ctx.audio.sfxVol + 0.25)
        ctx.save.data.audio.sfx = ctx.audio.sfxVol
        ctx.save.write()
    elseif id == "music" then
        ctx.audio.setMusicVolume(ctx.audio.musicVol >= 0.95 and 0 or ctx.audio.musicVol + 0.25)
        ctx.save.data.audio.music = ctx.audio.musicVol
        ctx.save.write()
    end
end

function debug.keypressed(ctx, f, key)
    if key == "escape" then ctx.router:pop() end
end

return debug
