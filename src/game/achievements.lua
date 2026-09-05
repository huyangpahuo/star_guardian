-- Achievements: definitions, per-run counters and sliding unlock popups.
-- Unlock state persists through the save file; per-run counters reset each run.
local achievements = {
    list = {},
    popups = {},
    popupDuration = 3.5,
    popupSlideTime = 0.4,
    gameData = nil,
}

local DEFS = {
    {id = "first_kill", nameKey = "ach_first_kill", descKey = "ach_first_kill_desc", check = function(d) return d.totalKills >= 1 end},
    {id = "killer", nameKey = "ach_killer", descKey = "ach_killer_desc", check = function(d) return d.totalKills >= 100 end},
    {id = "score_1000", nameKey = "ach_score_1000", descKey = "ach_score_1000_desc", check = function(d) return d.totalScore >= 1000 end},
    {id = "score_5000", nameKey = "ach_score_5000", descKey = "ach_score_5000_desc", check = function(d) return d.totalScore >= 5000 end},
    {id = "collector", nameKey = "ach_collector", descKey = "ach_collector_desc", check = function(d) return d.powerupsCollected >= 10 end},
    {id = "veteran", nameKey = "ach_veteran", descKey = "ach_veteran_desc", check = function(d) return d.maxLevel >= 10 end},
    {id = "flawless", nameKey = "ach_flawless", descKey = "ach_flawless_desc", check = function(d) return d.flawlessRounds >= 1 end},
    {id = "survivor", nameKey = "ach_survivor", descKey = "ach_survivor_desc", check = function(d) return d.maxRound >= 5 end},
}

-- unlocked: map of achievement id -> true, restored from the save file.
function achievements.init(unlocked)
    achievements.list = {}
    for _, def in ipairs(DEFS) do
        achievements.list[#achievements.list + 1] = {
            id = def.id,
            nameKey = def.nameKey,
            descKey = def.descKey,
            check = def.check,
            unlocked = (unlocked and unlocked[def.id]) or false,
        }
    end
    achievements.resetGameData()
    achievements.popups = {}
end

function achievements.resetGameData()
    achievements.gameData = {
        totalKills = 0, totalScore = 0, powerupsCollected = 0,
        maxLevel = 1, flawlessRounds = 0, currentRoundDamage = 0, maxRound = 1,
    }
end

function achievements.update(dt)
    for i = #achievements.popups, 1, -1 do
        local p = achievements.popups[i]
        p.timer = p.timer - dt
        p.slideTimer = p.slideTimer + dt
        if p.timer <= 0 then table.remove(achievements.popups, i) end
    end
end

-- Feed run events in; unlocks every newly-earned achievement and returns
-- them as a list (may be empty). Events: kills, score, powerup, level,
-- round, damage, roundComplete.
function achievements.check(data)
    local gd = achievements.gameData
    if data.kills then gd.totalKills = gd.totalKills + data.kills end
    if data.score then gd.totalScore = math.max(gd.totalScore, data.score) end
    if data.powerup then gd.powerupsCollected = gd.powerupsCollected + 1 end
    if data.level then gd.maxLevel = math.max(gd.maxLevel, data.level) end
    if data.round then gd.maxRound = math.max(gd.maxRound, data.round) end
    if data.damage then gd.currentRoundDamage = gd.currentRoundDamage + data.damage end
    if data.roundComplete then
        if gd.currentRoundDamage == 0 then gd.flawlessRounds = gd.flawlessRounds + 1 end
        gd.currentRoundDamage = 0
    end
    local unlocked = {}
    for _, ach in ipairs(achievements.list) do
        if not ach.unlocked and ach.check(gd) then
            ach.unlocked = true
            achievements.triggerPopup(ach)
            unlocked[#unlocked + 1] = ach
        end
    end
    return unlocked
end

function achievements.triggerPopup(ach)
    achievements.popups[#achievements.popups + 1] = {
        ach = ach, timer = achievements.popupDuration, slideTimer = 0,
    }
end

function achievements.unlockedIds()
    local map = {}
    for _, a in ipairs(achievements.list) do
        if a.unlocked then map[a.id] = true end
    end
    return map
end

function achievements.draw(screenW, screenH, i18n, assets)
    local scale = math.min(1.4, math.max(0.8, math.min(screenW, screenH) / 650))
    local cardW = 260 * scale
    local cardH = 75 * scale
    local margin = 15 * scale
    local startX = screenW - cardW - margin
    for i, p in ipairs(achievements.popups) do
        local targetY = margin + (i - 1) * (cardH + 10 * scale)
        local progress = math.min(1, p.slideTimer / achievements.popupSlideTime)
        local ease = 1 - (1 - progress) ^ 3
        local x = startX + (1 - ease) * (cardW + margin * 2)
        local alpha = 1
        if p.timer < 0.5 then alpha = p.timer / 0.5 end
        love.graphics.setColor(0.1, 0.12, 0.18, 0.92 * alpha)
        love.graphics.rectangle("fill", x, targetY, cardW, cardH, 8, 8)
        love.graphics.setColor(0.3, 0.7, 1, 0.6 * alpha)
        love.graphics.rectangle("line", x, targetY, cardW, cardH, 8, 8)
        love.graphics.setColor(1, 0.85, 0.2, 0.8 * alpha)
        love.graphics.rectangle("fill", x + 4, targetY + 8 * scale, 4, cardH - 16 * scale, 2, 2)
        love.graphics.setColor(1, 0.85, 0.2, alpha)
        assets.setFont(math.floor(16 * scale))
        love.graphics.print("★", x + 20 * scale, targetY + cardH / 2 - 10 * scale)
        love.graphics.setColor(1, 1, 1, alpha)
        assets.setFont(math.floor(15 * scale))
        love.graphics.print(i18n.t("achievement_unlocked"), x + 50 * scale, targetY + 10 * scale)
        assets.setFont(math.floor(14 * scale))
        love.graphics.setColor(0.8, 0.9, 1, alpha)
        love.graphics.print(i18n.t(p.ach.nameKey), x + 50 * scale, targetY + 32 * scale)
        love.graphics.setColor(0.6, 0.7, 0.8, alpha)
        love.graphics.print(i18n.t(p.ach.descKey), x + 50 * scale, targetY + 50 * scale)
    end
end

function achievements.getList() return achievements.list end

function achievements.isUnlocked(id)
    for _, a in ipairs(achievements.list) do
        if a.id == id then return a.unlocked end
    end
    return false
end

return achievements
