-- Gameplay scene: advances the world simulation, translates simulation
-- events into audio/score/achievements, draws the world and the HUD.
local runflow = require("src.game.runflow")

local playing = {name = "playing"}

function playing.update(ctx, f, dt)
    if ctx.input.consumePauseRequest() then
        ctx.audio.play("click")
        ctx.router:push("paused")
        return
    end

    local session = ctx.session
    local events = ctx.world.update(dt, session, ctx.input.actions)
    local unlockedAll = {}
    local died = false

    for _, ev in ipairs(events) do
        if ev.type == "shoot" then
            ctx.audio.play("shoot")
        elseif ev.type == "hit" then
            ctx.audio.play("hit")
        elseif ev.type == "kill" then
            ctx.audio.play("explosion")
            session.addScore(ev.score)
            session.kills = session.kills + 1
            for _, a in ipairs(ctx.achievements.check({kills = 1, score = session.score, level = session.level, round = session.roundNum})) do
                unlockedAll[#unlockedAll + 1] = a
            end
        elseif ev.type == "powerup" then
            ctx.audio.play("powerup")
            for _, a in ipairs(ctx.achievements.check({powerup = true})) do
                unlockedAll[#unlockedAll + 1] = a
            end
        elseif ev.type == "player_hit" then
            session.damageTaken = session.damageTaken + ev.damage
        elseif ev.type == "died" then
            died = true
        end
    end

    if died then
        runflow.finish(ctx)
        return
    end

    for _, a in ipairs(ctx.achievements.check({score = session.score, level = session.level})) do
        unlockedAll[#unlockedAll + 1] = a
    end
    if #unlockedAll > 0 then
        ctx.audio.play("achievement")
        ctx.persistAchievements()
    end

    -- round advance pauses the action behind a transition overlay
    if ctx.rounds.checkAdvance(session.score, session.roundNum) then
        session.roundNum = session.roundNum + 1
        ctx.audio.play("levelup")
        local unlocked = ctx.achievements.check({round = session.roundNum})
        if session.damageTaken == 0 then
            for _, a in ipairs(ctx.achievements.check({roundComplete = true})) do
                unlocked[#unlocked + 1] = a
            end
        end
        session.damageTaken = 0
        if #unlocked > 0 then
            ctx.audio.play("achievement")
            ctx.persistAchievements()
        end
        ctx.router:push("round_transition")
    end
end

local function drawHUD(ctx)
    local C = ctx.theme.colors
    local w, h = ctx.w, ctx.h
    local m = ctx.theme.metrics(w, h)
    local margin = m.margin
    local fs = m.body
    local i18n = ctx.i18n
    local session = ctx.session
    local player = ctx.world.player

    love.graphics.setColor(1, 1, 1)
    ctx.assets.setFont(math.floor(fs * 1.05))
    love.graphics.print(i18n.t("score") .. ": " .. session.score, margin, margin)
    ctx.assets.setFont(math.floor(fs * 0.82))
    love.graphics.print(i18n.t("highscore") .. ": " .. session.highscore, margin, margin + fs * 1.45)
    love.graphics.setColor(0.4, 0.9, 1)
    ctx.assets.setFont(math.floor(fs * 0.9))
    love.graphics.print(i18n.t("level") .. ": " .. session.level, margin, margin + fs * 2.7)
    love.graphics.setColor(0.6, 0.8, 1)
    ctx.assets.setFont(math.floor(fs * 0.8))
    love.graphics.print(i18n.t("round") .. " " .. session.roundNum, margin, margin + fs * 4.0)

    -- HP bar, top right
    local barW = math.min(220, w * 0.26)
    local barH = math.max(16, fs)
    local barX = w - barW - margin
    local barY = margin
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)
    local ratio = math.max(0, player.hp / player.maxHp)
    local hpC = ctx.theme.hpColor(ratio)
    love.graphics.setColor(hpC[1], hpC[2], hpC[3])
    love.graphics.rectangle("fill", barX, barY, barW * ratio, barH, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    ctx.assets.setFont(math.floor(barH * 0.72))
    local hpText = i18n.t("hp") .. " " .. math.ceil(math.max(0, player.hp)) .. "/" .. player.maxHp
    love.graphics.print(hpText, barX + barW / 2 - love.graphics.getFont():getWidth(hpText) / 2, barY + 1)
end

function playing.draw(ctx, f)
    ctx.world.draw()
    drawHUD(ctx)
    ctx.input.drawButtons(ctx.assets)
end

function playing.keypressed(ctx, f, key)
    if key == "p" then
        ctx.audio.play("click")
        ctx.router:push("paused")
    elseif key == "escape" then
        ctx.audio.play("click")
        ctx.router:push("exit_prompt")
    end
end

return playing
