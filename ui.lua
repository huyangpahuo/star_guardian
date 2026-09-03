local utils = require("utils")

local ui = {sliders = {}, animTimer = 0, selectedShipIndex = 1, shipAnimOffset = 0}

function ui.drawButton(x, y, w, h, text, assets, isHovered, isPressed, baseColor)
    local c = baseColor or {0.2, 0.5, 0.9}
    local brightness = isPressed and 1.25 or (isHovered and 1.08 or 1.0)
    love.graphics.setColor(c[1] * brightness, c[2] * brightness, c[3] * brightness, 0.86)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
    local fs = math.floor(h * 0.38)
    assets.setFont(fs)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + w/2 - love.graphics.getFont():getWidth(text)/2, y + h/2 - assets.getFont(fs):getHeight()/2)
end
function ui.drawSlider(x, y, w, h, label, value, assets, i18n) local labelSize = math.floor(h * 0.9); assets.setFont(labelSize); love.graphics.setColor(0.7, 0.8, 0.9); love.graphics.print(label, x, y - labelSize - 4); love.graphics.setColor(0.15, 0.18, 0.25); love.graphics.rectangle("fill", x, y + h/2 - 3, w, 6, 3, 3); love.graphics.setColor(0.3, 0.7, 1); love.graphics.rectangle("fill", x, y + h/2 - 3, w * value, 6, 3, 3); local knobX = x + w * value; local knobR = h * 0.5; love.graphics.setColor(0.4, 0.8, 1); love.graphics.circle("fill", knobX, y + h/2, knobR); love.graphics.setColor(1, 1, 1, 0.5); love.graphics.circle("line", knobX, y + h/2, knobR); love.graphics.setColor(0.8, 0.9, 1); assets.setFont(math.floor(labelSize * 0.8)); local valText = math.floor(value * 100) .. "%"; love.graphics.print(valText, x + w + 12, y + h/2 - labelSize*0.4); return knobX end
function ui.drawStatBar(x, y, w, h, label, value, color, assets, i18n) assets.setFont(math.floor(h * 1.2)); love.graphics.setColor(0.7, 0.8, 0.9); love.graphics.print(label, x, y - h * 1.5); love.graphics.setColor(0.15, 0.18, 0.25); love.graphics.rectangle("fill", x, y, w, h, 4, 4); love.graphics.setColor(color[1], color[2], color[3]); love.graphics.rectangle("fill", x, y, w * value, h, 4, 4); love.graphics.setColor(1, 1, 1, 0.2); love.graphics.rectangle("line", x, y, w, h, 4, 4) end

function ui.drawFractalBackdrop(game, phase)
    local w, h = game.width, game.height
    local t = phase or 0
    for i = 1, 6 do
        local a = 0.04 + i * 0.015
        local r = math.min(w, h) * (0.18 + i * 0.07)
        local x = w * 0.5 + math.sin(t * 0.4 + i) * w * 0.08
        local y = h * 0.42 + math.cos(t * 0.35 + i * 1.3) * h * 0.04
        love.graphics.setColor(0.15 + i * 0.04, 0.22 + i * 0.03, 0.35 + i * 0.02, a)
        love.graphics.circle("fill", x, y, r, 48)
    end
end

function ui.drawMenu(game, i18n, assets, world, dt)
    ui.animTimer = ui.animTimer + dt
    local cx, cy = game.width/2, game.height/2
    local titleSize = math.min(game.width, game.height) * 0.085
    ui.drawFractalBackdrop(game, ui.animTimer)
    love.graphics.setColor(0.06, 0.08, 0.14, 0.38)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    assets.setFont(math.floor(titleSize))
    love.graphics.setColor(0.4, 0.8, 1)
    local title = i18n.t("title")
    love.graphics.print(title, cx - love.graphics.getFont():getWidth(title)/2, cy - titleSize * 3.4)
    assets.setFont(math.floor(titleSize * 0.42))
    love.graphics.setColor(0.5, 0.8, 1, 0.7)
    local sub = i18n.t("subtitle")
    love.graphics.print(sub, cx - love.graphics.getFont():getWidth(sub)/2, cy - titleSize * 2.25)
    local previewY = cy - titleSize * 0.35 + math.sin(ui.animTimer * 2) * 8
    if world.player then local saved = {x = world.player.x, y = world.player.y}; world.player.x, world.player.y = cx, previewY; world.drawPlayer(); world.player.x, world.player.y = saved.x, saved.y end
    local btnW = math.min(340, game.width * 0.52)
    local btnH = math.min(60, game.height * 0.085)
    local btnGap = btnH * 1.55
    local startY = cy + titleSize * 0.95
    local mx, my = love.mouse.getPosition()
    local buttons = {{key = "start", text = i18n.t("start"), y = startY, color = {0.25, 0.72, 1}}, {key = "ship_select", text = i18n.t("ship_select"), y = startY + btnGap, color = {0.38, 0.58, 0.95}}, {key = "settings", text = i18n.t("settings"), y = startY + btnGap * 2, color = {0.38, 0.58, 0.95}}, {key = "lang", text = i18n.t("language_menu"), y = startY + btnGap * 3, color = {0.55, 0.55, 1}}}
    for _, btn in ipairs(buttons) do local bx = cx - btnW/2; local hovered = utils.pointInRect(mx, my, bx, btn.y, btnW, btnH); ui.drawButton(bx, btn.y, btnW, btnH, btn.text, assets, hovered, false, btn.color) end
    if math.sin(ui.animTimer * 4) > 0 then love.graphics.setColor(1, 0.9, 0.3); assets.setFont(math.floor(titleSize * 0.28)); local hint = game.isMobile and i18n.t("tap_hint") or i18n.t("start_hint"); love.graphics.print(hint, cx - love.graphics.getFont():getWidth(hint)/2, startY + btnGap * 3.25) end
    ui.drawLangButtons(game, i18n, assets, startY + btnGap * 5.15)
    return buttons
end

function ui.drawLanguageMenu(game, i18n, assets)
    local cx, cy = game.width/2, game.height/2
    ui.drawFractalBackdrop(game, ui.animTimer * 0.7)
    love.graphics.setColor(0.08, 0.1, 0.18, 0.34)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    assets.setFont(math.floor(math.min(game.width, game.height) * 0.075))
    love.graphics.setColor(0.4, 0.85, 1)
    local title = i18n.t("language_menu")
    love.graphics.print(title, cx - love.graphics.getFont():getWidth(title)/2, cy - 160)
    local langs = {"en", "zh_CN", "ja"}
    local btnW = math.min(300, game.width * 0.45)
    local btnH = 54
    local startY = cy - 70
    for i, code in ipairs(langs) do
        local y = startY + (i - 1) * 70
        ui.drawButton(cx - btnW/2, y, btnW, btnH, i18n.getName(code), assets, false, false, code == i18n.lang and {0.35, 0.9, 0.55} or {0.3, 0.5, 0.95})
    end
    ui.drawButton(cx - btnW/2, cy + 160, btnW, btnH, i18n.t("back"), assets, false, false, {0.5, 0.5, 0.6})
end

function ui.getLanguageMenuChoice(game, x, y)
    local cx, cy = game.width/2, game.height/2
    local langs = {"en", "zh_CN", "ja"}
    local btnW = math.min(300, game.width * 0.45)
    local btnH = 54
    local startY = cy - 70
    for i, code in ipairs(langs) do
        local by = startY + (i - 1) * 70
        if utils.pointInRect(x, y, cx - btnW/2, by, btnW, btnH) then return code end
    end
    if utils.pointInRect(x, y, cx - btnW/2, cy + 160, btnW, btnH) then return false end
end

function ui.drawShipSelect(game, i18n, assets, player, world, dt)
    ui.animTimer = ui.animTimer + dt
    local cx, cy = game.width/2, game.height/2
    local titleSize = math.min(game.width, game.height) * 0.07
    ui.drawFractalBackdrop(game, ui.animTimer * 0.8)
    love.graphics.setColor(0.02, 0.03, 0.08, 0.55)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    assets.setFont(math.floor(titleSize))
    love.graphics.setColor(0.4, 0.8, 1)
    local title = i18n.t("ship_select")
    love.graphics.print(title, cx - love.graphics.getFont():getWidth(title)/2, 30)
    local order = player.getOrder()
    local idx = ui.selectedShipIndex
    local shipId = order[idx]
    local cfg = player.getTypes()[shipId]
    local arrowSize = math.min(game.width, game.height) * 0.06
    local arrowY = cy - arrowSize
    local leftX = cx - game.width * 0.35
    local rightX = cx + game.width * 0.35
    love.graphics.setColor(0.4, 0.7, 1, 0.6)
    assets.setFont(math.floor(arrowSize * 1.5))
    love.graphics.print("◀", leftX - love.graphics.getFont():getWidth("◀")/2, arrowY)
    love.graphics.print("▶", rightX - love.graphics.getFont():getWidth("▶")/2, arrowY)
    ui.shipAnimOffset = utils.lerp(ui.shipAnimOffset, 0, dt * 8)
    local previewX = cx + ui.shipAnimOffset
    local previewY = cy - titleSize * 0.45 + math.sin(ui.animTimer * 2) * 6
    local savedColor = world.player.color
    local savedType = world.player.shipType
    world.player.color = cfg.color
    world.player.shipType = cfg.id
    world.player.x = previewX
    world.player.y = previewY
    world.drawPlayer()
    world.player.color = savedColor
    world.player.shipType = savedType
    assets.setFont(math.floor(titleSize * 0.5))
    love.graphics.setColor(1, 1, 1)
    local name = i18n.t(cfg.nameKey)
    love.graphics.print(name, cx - love.graphics.getFont():getWidth(name)/2, previewY + 42)
    love.graphics.setColor(0.7, 0.85, 1)
    assets.setFont(math.floor(titleSize * 0.3))
    local skill = i18n.t(cfg.skillKey)
    love.graphics.print(skill, cx - love.graphics.getFont():getWidth(skill)/2, previewY + 72)
    local barW = math.min(340, game.width * 0.55)
    local barH = 12
    local barX = cx - barW/2
    local barStartY = previewY + 120
    local barGap = 34
    ui.drawStatBar(barX, barStartY, barW, barH, i18n.t("stats_speed"), cfg.stats.speed, {0.2, 0.8, 1}, assets, i18n)
    ui.drawStatBar(barX, barStartY + barGap, barW, barH, i18n.t("stats_firepower"), cfg.stats.firepower, {1, 0.4, 0.2}, assets, i18n)
    ui.drawStatBar(barX, barStartY + barGap*2, barW, barH, i18n.t("stats_hp"), cfg.stats.hp, {0.2, 0.9, 0.3}, assets, i18n)
    local btnW = math.min(220, game.width * 0.38)
    local btnH = 48
    local mx, my = love.mouse.getPosition()
    local selectBtn = {x = cx - btnW/2, y = game.height - 150, w = btnW, h = btnH}
    local backBtn = {x = cx - btnW/2, y = game.height - 85, w = btnW, h = btnH}
    ui.drawButton(selectBtn.x, selectBtn.y, selectBtn.w, selectBtn.h, i18n.t("select"), assets, utils.pointInRect(mx, my, selectBtn.x, selectBtn.y, selectBtn.w, selectBtn.h), false, {0.2, 0.7, 0.4})
    ui.drawButton(backBtn.x, backBtn.y, backBtn.w, backBtn.h, i18n.t("back"), assets, utils.pointInRect(mx, my, backBtn.x, backBtn.y, backBtn.w, backBtn.h), false, {0.5, 0.5, 0.6})
    return {select = selectBtn, back = backBtn, leftArrow = {x = leftX, y = arrowY, r = arrowSize}, rightArrow = {x = rightX, y = arrowY, r = arrowSize}}
end

function ui.drawSettings(game, i18n, assets, audio, dt)
    ui.animTimer = ui.animTimer + dt
    local cx, cy = game.width/2, game.height/2
    local titleSize = math.min(game.width, game.height) * 0.07
    ui.drawFractalBackdrop(game, ui.animTimer * 0.6)
    love.graphics.setColor(0.06, 0.08, 0.14, 0.38)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    assets.setFont(math.floor(titleSize))
    love.graphics.setColor(0.4, 0.8, 1)
    local title = i18n.t("settings")
    love.graphics.print(title, cx - love.graphics.getFont():getWidth(title)/2, 34)
    local sliderW = math.min(460, game.width * 0.65)
    local sliderH = 30
    local sliderX = cx - sliderW/2
    local startY = cy - titleSize * 1.35
    local gap = 96
    if not ui.sliders.master then ui.sliders.master = {x = sliderX, y = startY, width = sliderW, height = sliderH, value = audio.masterVol, knobY = startY + sliderH/2}; ui.sliders.sfx = {x = sliderX, y = startY + gap, width = sliderW, height = sliderH, value = audio.sfxVol, knobY = startY + gap + sliderH/2}; ui.sliders.music = {x = sliderX, y = startY + gap * 2, width = sliderW, height = sliderH, value = audio.musicVol, knobY = startY + gap * 2 + sliderH/2} end
    ui.sliders.master.knobX = ui.drawSlider(sliderX, startY, sliderW, sliderH, i18n.t("master_vol"), ui.sliders.master.value, assets, i18n)
    ui.sliders.sfx.knobX = ui.drawSlider(sliderX, startY + gap, sliderW, sliderH, i18n.t("sfx_vol"), ui.sliders.sfx.value, assets, i18n)
    ui.sliders.music.knobX = ui.drawSlider(sliderX, startY + gap * 2, sliderW, sliderH, i18n.t("music_vol"), ui.sliders.music.value, assets, i18n)
    local btnW = math.min(220, game.width * 0.38)
    local btnH = 48
    local mx, my = love.mouse.getPosition()
    local backBtn = {x = cx - btnW/2, y = game.height - 92, w = btnW, h = btnH}
    ui.drawButton(backBtn.x, backBtn.y, backBtn.w, backBtn.h, i18n.t("back"), assets, utils.pointInRect(mx, my, backBtn.x, backBtn.y, backBtn.w, backBtn.h), false, {0.5, 0.5, 0.6})
    return {back = backBtn, sliders = ui.sliders}
end

function ui.drawRoundTransition(game, i18n, assets, rounds, dt)
    ui.animTimer = ui.animTimer + dt
    local cx, cy = game.width/2, game.height/2
    local titleSize = math.min(game.width, game.height) * 0.08
    ui.drawFractalBackdrop(game, ui.animTimer * 0.55)
    love.graphics.setColor(0.02, 0.03, 0.08, 0.72)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    assets.setFont(math.floor(titleSize * 0.7))
    love.graphics.setColor(0.3, 0.9, 0.5)
    local complete = i18n.t("round_complete")
    love.graphics.print(complete, cx - love.graphics.getFont():getWidth(complete)/2, cy - titleSize * 3)
    assets.setFont(math.floor(titleSize))
    love.graphics.setColor(1, 1, 1)
    local roundText = i18n.t("round") .. " " .. (game.roundNum - 1)
    love.graphics.print(roundText, cx - love.graphics.getFont():getWidth(roundText)/2, cy - titleSize * 1.8)
    local nextCfg = rounds.getConfig(game.roundNum)
    assets.setFont(math.floor(titleSize * 0.55))
    love.graphics.setColor(0.6, 0.8, 1)
    local nextText = i18n.t("next_round") .. ": " .. nextCfg.name
    love.graphics.print(nextText, cx - love.graphics.getFont():getWidth(nextText)/2, cy - titleSize * 0.3)
    assets.setFont(math.floor(titleSize * 0.4))
    love.graphics.setColor(0.7, 0.75, 0.85)
    love.graphics.print(nextCfg.desc, cx - love.graphics.getFont():getWidth(nextCfg.desc)/2, cy + titleSize * 0.5)
    love.graphics.setColor(1, 0.9, 0.3)
    assets.setFont(math.floor(titleSize * 0.45))
    local scoreText = i18n.t("score") .. ": " .. game.score
    love.graphics.print(scoreText, cx - love.graphics.getFont():getWidth(scoreText)/2, cy + titleSize * 1.3)
    local btnW = math.min(240, game.width * 0.42)
    local btnH = 52
    local mx, my = love.mouse.getPosition()
    local contBtn = {x = cx - btnW/2, y = cy + titleSize * 2.2, w = btnW, h = btnH}
    ui.drawButton(contBtn.x, contBtn.y, contBtn.w, contBtn.h, i18n.t("continue"), assets, utils.pointInRect(mx, my, contBtn.x, contBtn.y, contBtn.w, contBtn.h), false, {0.2, 0.7, 0.5})
    if math.sin(ui.animTimer * 3) > 0 then love.graphics.setColor(1, 1, 1, 0.6); assets.setFont(math.floor(titleSize * 0.3)); local tap = game.isMobile and i18n.t("continue_tap") or i18n.t("continue_hint"); love.graphics.print(tap, cx - love.graphics.getFont():getWidth(tap)/2, contBtn.y + btnH + 15) end
    return {continue = contBtn}
end
function ui.drawHUD(game, world, i18n, assets)
    local margin = math.min(game.width, game.height) * 0.03
    local fontSize = math.min(game.width, game.height) * 0.036
    love.graphics.setColor(1, 1, 1)
    assets.setFont(math.floor(fontSize * 1.05))
    love.graphics.print(i18n.t("score") .. ": " .. game.score, margin, margin)
    assets.setFont(math.floor(fontSize * 0.82))
    love.graphics.print(i18n.t("highscore") .. ": " .. game.highscore, margin, margin + fontSize * 1.45)
    love.graphics.setColor(0.4, 0.9, 1)
    assets.setFont(math.floor(fontSize * 0.9))
    love.graphics.print(i18n.t("level") .. ": " .. game.level, margin, margin + fontSize * 2.7)
    love.graphics.setColor(0.6, 0.8, 1)
    assets.setFont(math.floor(fontSize * 0.8))
    love.graphics.print(i18n.t("round") .. " " .. game.roundNum, margin, margin + fontSize * 4.0)
    local barW = math.min(220, game.width * 0.26)
    local barH = math.max(16, fontSize)
    local barX = game.width - barW - margin
    local barY = margin
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)
    local hpR = math.max(0, world.player.hp / world.player.maxHp)
    local hpC = hpR > 0.5 and {0.2,0.9,0.3} or (hpR > 0.25 and {1,0.8,0.2} or {1,0.2,0.2})
    love.graphics.setColor(hpC[1], hpC[2], hpC[3])
    love.graphics.rectangle("fill", barX, barY, barW * hpR, barH, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    assets.setFont(math.floor(barH * 0.72))
    local hpText = i18n.t("hp") .. " " .. math.ceil(world.player.hp) .. "/" .. world.player.maxHp
    love.graphics.print(hpText, barX + barW/2 - love.graphics.getFont():getWidth(hpText)/2, barY + 1)
end
function ui.drawPaused(game, i18n, assets) love.graphics.setColor(0, 0, 0, 0.6); love.graphics.rectangle("fill", 0, 0, game.width, game.height); local cx, cy = game.width/2, game.height/2; local fs = math.min(game.width, game.height) * 0.08; love.graphics.setColor(1, 1, 1); assets.setFont(math.floor(fs)); local text = i18n.t("paused"); love.graphics.print(text, cx - love.graphics.getFont():getWidth(text)/2, cy - fs); assets.setFont(math.floor(fs * 0.45)); love.graphics.setColor(0.7, 0.8, 1); local hint = game.isMobile and i18n.t("continue_tap") or i18n.t("continue_hint"); love.graphics.print(hint, cx - love.graphics.getFont():getWidth(hint)/2, cy + fs * 0.3) end
function ui.drawExitPrompt(game, i18n, assets) love.graphics.setColor(0, 0, 0, 0.72); love.graphics.rectangle("fill", 0, 0, game.width, game.height); local cx, cy = game.width/2, game.height/2; assets.setFont(math.floor(math.min(game.width, game.height) * 0.055)); local title = "Return to Menu?"; love.graphics.setColor(1,1,1); love.graphics.print(title, cx - love.graphics.getFont():getWidth(title)/2, cy - 70); assets.setFont(math.floor(math.min(game.width, game.height) * 0.035)); local msg = "Press Enter, or choose a button below."; love.graphics.setColor(0.8,0.85,1); love.graphics.print(msg, cx - love.graphics.getFont():getWidth(msg)/2, cy - 30); local btnW = math.min(240, game.width * 0.35); local btnH = 50; local yesBtn = {x = cx - btnW/2, y = cy + 20, w = btnW, h = btnH}; local noBtn = {x = cx - btnW/2, y = cy + 90, w = btnW, h = btnH}; ui.drawButton(yesBtn.x, yesBtn.y, yesBtn.w, yesBtn.h, "Yes", assets, false, false, {0.7,0.35,0.25}); ui.drawButton(noBtn.x, noBtn.y, noBtn.w, noBtn.h, "No", assets, false, false, {0.25,0.55,0.85}) end
function ui.drawExitButton(game, i18n, assets)
    local w, h = game.width, game.height
    local bw = math.min(160, w * 0.18)
    local bh = math.min(38, h * 0.055)
    local x = w - bw - math.max(16, w * 0.02)
    local y = math.max(16, h * 0.02)
    local mx, my = love.mouse.getPosition()
    ui.drawButton(x, y, bw, bh, "Exit", assets, false, false, {0.75, 0.3, 0.28})
    ui.exitButton = {x = x, y = y, w = bw, h = bh}
end

function ui.drawDebugPanel(game, i18n, assets, audio, input, saveData, dt)
    ui.animTimer = ui.animTimer + dt
    local cx, cy = game.width/2, game.height/2
    ui.drawFractalBackdrop(game, ui.animTimer * 0.4)
    love.graphics.setColor(0.05, 0.07, 0.12, 0.82)
    love.graphics.rectangle("fill", 0, 0, game.width, game.height)
    local panelW = math.min(760, game.width * 0.88)
    local panelH = math.min(560, game.height * 0.85)
    local px = cx - panelW/2
    local py = cy - panelH/2
    love.graphics.setColor(0.1, 0.14, 0.22, 0.95)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 16, 16)
    love.graphics.setColor(0.45, 0.75, 1, 0.55)
    love.graphics.rectangle("line", px, py, panelW, panelH, 16, 16)
    assets.setFont(math.floor(math.min(game.width, game.height) * 0.055))
    love.graphics.setColor(1, 1, 1)
    local title = "Debug Panel"
    love.graphics.print(title, px + 28, py + 18)
    assets.setFont(math.floor(math.min(game.width, game.height) * 0.03))
    love.graphics.setColor(0.75, 0.86, 1)
    love.graphics.print("F1 close  |  Save is automatic", px + 28, py + 62)
    local left = px + 28
    local top = py + 110
    local bw = 220
    local bh = 42
    ui.drawButton(left, top, bw, bh, "Language: " .. i18n.lang, assets, false, false, {0.35, 0.55, 0.95})
    ui.drawButton(left, top + 56, bw, bh, "Fullscreen: " .. tostring(game.isFullscreen and "On" or "Off"), assets, false, false, {0.35, 0.75, 0.55})
    ui.drawButton(left, top + 112, bw, bh, "Back", assets, false, false, {0.5, 0.5, 0.6})
    ui.drawButton(left + 250, top, bw, bh, "Master " .. math.floor(audio.masterVol * 100) .. "%", assets, false, false, {0.4, 0.7, 1})
    ui.drawButton(left + 250, top + 56, bw, bh, "SFX " .. math.floor(audio.sfxVol * 100) .. "%", assets, false, false, {0.4, 0.7, 1})
    ui.drawButton(left + 250, top + 112, bw, bh, "Music " .. math.floor(audio.musicVol * 100) .. "%", assets, false, false, {0.4, 0.7, 1})
    local stats = saveData.stats or {runs = 0, bestScore = 0, totalScore = 0, kills = 0, deaths = 0, damageTaken = 0}
    assets.setFont(math.floor(math.min(game.width, game.height) * 0.028))
    love.graphics.setColor(0.9, 0.95, 1)
    local lines = {
        "Runs: " .. stats.runs,
        "Best Score: " .. stats.bestScore,
        "Total Score: " .. stats.totalScore,
        "Kills: " .. stats.kills,
        "Deaths: " .. stats.deaths,
        "Damage Taken: " .. stats.damageTaken,
        "Input L/R/Shoot: " .. tostring(input.state.left) .. " / " .. tostring(input.state.right) .. " / " .. tostring(input.state.shoot),
    }
    for i, line in ipairs(lines) do love.graphics.print(line, left, top + 190 + (i - 1) * 28) end
    ui.debugRects = {
        language = {x = left, y = top, w = bw, h = bh},
        fullscreen = {x = left, y = top + 56, w = bw, h = bh},
        back = {x = left, y = top + 112, w = bw, h = bh},
        master = {x = left + 250, y = top, w = bw, h = bh},
        sfx = {x = left + 250, y = top + 56, w = bw, h = bh},
        music = {x = left + 250, y = top + 112, w = bw, h = bh},
    }
end

function ui.handleDebugClick(game, x, y, saveData)
    local r = ui.debugRects or {}
    if r.language and utils.pointInRect(x, y, r.language.x, r.language.y, r.language.w, r.language.h) then
        game.state = "language_menu"
        return nil
    elseif r.fullscreen and utils.pointInRect(x, y, r.fullscreen.x, r.fullscreen.y, r.fullscreen.w, r.fullscreen.h) then
        game.isFullscreen = not game.isFullscreen
        love.window.setMode(0, 0, {fullscreen = game.isFullscreen, fullscreentype = "desktop", vsync = true, highdpi = true})
        game.resize(love.graphics.getDimensions())
        game.save()
        return nil
    elseif r.back and utils.pointInRect(x, y, r.back.x, r.back.y, r.back.w, r.back.h) then
        return "back"
    end
    return nil
end

function ui.updateDebugSlider(name, x, saveData, audio)
    if not ui.debugRects then return end
end
function ui.drawGameOver(game, i18n, assets, world) love.graphics.setColor(0, 0, 0, 0.7); love.graphics.rectangle("fill", 0, 0, game.width, game.height); local cx, cy = game.width/2, game.height/2; local fs = math.min(game.width, game.height) * 0.09; love.graphics.setColor(1, 0.3, 0.2); assets.setFont(math.floor(fs)); local text = i18n.t("game_over"); love.graphics.print(text, cx - love.graphics.getFont():getWidth(text)/2, cy - fs * 2.5); love.graphics.setColor(1, 1, 1); assets.setFont(math.floor(fs * 0.5)); local st = i18n.t("final_score") .. ": " .. game.score; love.graphics.print(st, cx - love.graphics.getFont():getWidth(st)/2, cy - fs * 1.2); if game.score >= game.highscore and game.score > 0 then love.graphics.setColor(1, 0.9, 0.2); assets.setFont(math.floor(fs * 0.4)); local nr = i18n.t("new_record"); love.graphics.print(nr, cx - love.graphics.getFont():getWidth(nr)/2, cy - fs * 0.4) end; love.graphics.setColor(0.7, 0.8, 1); assets.setFont(math.floor(fs * 0.35)); local hs = i18n.t("highscore") .. ": " .. game.highscore; love.graphics.print(hs, cx - love.graphics.getFont():getWidth(hs)/2, cy + fs * 0.3); if math.sin(love.timer.getTime() * 3) > 0 then love.graphics.setColor(1, 0.9, 0.3); assets.setFont(math.floor(fs * 0.4)); local rt = game.isMobile and i18n.t("restart_tap") or i18n.t("restart_hint"); love.graphics.print(rt, cx - love.graphics.getFont():getWidth(rt)/2, cy + fs * 1.2) end end
function ui.drawVirtualButtons(input, gameState, assets) if not input or not input.getButtons then return end; if not gameState or not gameState:match("playing") or not input.showTouchControls then return end; for name, btn in pairs(input.getButtons()) do local alpha = input.isPressed(name) and 0.7 or 0.3; love.graphics.setColor(btn.color[1], btn.color[2], btn.color[3], alpha); love.graphics.circle("fill", btn.x, btn.y, btn.size/2); love.graphics.setColor(1, 1, 1, 0.35); love.graphics.circle("line", btn.x, btn.y, btn.size/2); love.graphics.setColor(1, 1, 1, 0.85); local ls = btn.size * 0.45; assets.setFont(math.floor(ls)); love.graphics.print(btn.label, btn.x - love.graphics.getFont():getWidth(btn.label)/2, btn.y - ls * 0.4) end end
function ui.drawLangButtons(game, i18n, assets, y) local langs = {{code = "en", label = "EN"}, {code = "zh", label = "中文"}, {code = "ja", label = "日本語"}}; local btnSize = math.min(game.width, game.height) * 0.035; local gap = btnSize * 3; local startX = game.width/2 - (#langs - 1) * gap / 2; assets.setFont(math.floor(btnSize * 0.9)); love.graphics.setColor(0.5, 0.5, 0.6, 0.7); love.graphics.print(i18n.t("lang_label") .. ":", startX - btnSize * 4, y); for i, lang in ipairs(langs) do local bx = startX + (i - 1) * gap; local isActive = i18n.lang == lang.code; if isActive then love.graphics.setColor(0.3, 0.6, 1, 0.4); love.graphics.circle("fill", bx, y + btnSize/2, btnSize * 1.1) end; love.graphics.setColor(isActive and {1,1,1} or {0.5,0.5,0.6}); love.graphics.print(lang.label, bx - love.graphics.getFont():getWidth(lang.label)/2, y) end end
function ui.getLangButtonAreas(game, i18n) local langs = {{code = "en"}, {code = "zh"}, {code = "ja"}}; local btnSize = math.min(game.width, game.height) * 0.035; local gap = btnSize * 3; local startX = game.width/2 - (#langs - 1) * gap / 2; local y = game.height/2 + math.min(game.width, game.height) * 0.085 * 4.2; local areas = {}; for i, lang in ipairs(langs) do local bx = startX + (i - 1) * gap; table.insert(areas, {code = lang.code, x = bx, y = y + btnSize/2, r = btnSize * 1.2}) end; return areas end
return ui
