local utils = require("utils")

local game = {
    state = "menu",
    score = 0, highscore = 0, level = 1, roundNum = 1,
    width = 900, height = 650,
    isMobile = false,
    modules = {},
    app = nil,
    lastPauseState = false,
    prevState = nil,
    saveData = nil,
    shader = nil,
    canvas = nil,
    pendingExit = false,
    debugOpen = false,
    debugTab = "stats",
}

function game.init(modules)
    game.modules = modules
    game.app = modules.app
    game.isMobile = (love.system.getOS() == "Android" or love.system.getOS() == "iOS")
    love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "desktop", vsync = true})
    love.window.setMode(game.width, game.height, {resizable = false, fullscreen = false, highdpi = true, vsync = true})
    game.width, game.height = love.graphics.getDimensions()
    game.canvas = love.graphics.newCanvas(game.width, game.height)
    modules.world.init(game.width, game.height)
    modules.input.init(game.width, game.height)
    modules.audio.init()
    modules.achievements.init()
    modules.player.select("striker")
    modules.player.applyToWorld(modules.world.player, game.height)
    if love.filesystem.getInfo("resources/shaders/post.glsl") then
        local ok, shader = pcall(love.graphics.newShader, love.filesystem.read("resources/shaders/post.glsl"))
        if ok then game.shader = shader end
    end
    if modules.meta then
        game.saveData = modules.meta.load() or {}
        if game.saveData.lang then modules.i18n.setLang(game.saveData.lang) else modules.i18n.setLang("en") end
        if game.saveData.ship then modules.player.select(game.saveData.ship) end
        if game.saveData.highscore then game.highscore = game.saveData.highscore end
        if game.saveData.audio then
            if game.saveData.audio.master then modules.audio.setMasterVolume(game.saveData.audio.master) end
            if game.saveData.audio.sfx then modules.audio.setSfxVolume(game.saveData.audio.sfx) end
            if game.saveData.audio.music then modules.audio.setMusicVolume(game.saveData.audio.music) end
        end
    end
    game.save()
end

function game.save()
    if not game.modules.meta then return end
    local highscore = math.max(game.highscore, game.score)
    game.highscore = highscore
    local stats = game.saveData and game.saveData.stats or {runs = 0, bestScore = 0, totalScore = 0, kills = 0, deaths = 0, damageTaken = 0, lastRun = nil}
    game.modules.meta.write({
        lang = game.modules.i18n.lang,
        ship = game.modules.player.getCurrentId(),
        highscore = highscore,
        audio = {master = game.modules.audio.masterVol, sfx = game.modules.audio.sfxVol, music = game.modules.audio.musicVol},
        fullscreen = game.isFullscreen,
        stats = stats,
    })
    game.saveData = {lang = game.modules.i18n.lang, ship = game.modules.player.getCurrentId(), highscore = highscore, audio = {master = game.modules.audio.masterVol, sfx = game.modules.audio.sfxVol, music = game.modules.audio.musicVol}, fullscreen = game.isFullscreen, stats = stats}
end

function game.reset()
    game.score = 0; game.level = 1; game.roundNum = 1
    game.modules.world.reset(game.width, game.height)
    game.modules.player.applyToWorld(game.modules.world.player, game.height)
    game.modules.achievements.resetGameData()
    if not game.saveData then game.saveData = {} end
    game.saveData.stats = game.saveData.stats or {runs = 0, bestScore = 0, totalScore = 0, kills = 0, deaths = 0, damageTaken = 0, lastRun = nil}
    game.saveData.stats.runs = game.saveData.stats.runs + 1
    game.lastPauseState = false
end

function game.getProfile()
    return game.saveData or {}
end

function game.update(dt)
    game.width, game.height = love.graphics.getDimensions()
    local input = game.modules.input
    local world = game.modules.world
    local audio = game.modules.audio
    local achievements = game.modules.achievements
    local rounds = game.modules.rounds
    local ui = game.modules.ui
    input.update()
    achievements.update(dt)
    ui.animTimer = (ui.animTimer or 0) + dt
    if input.checkPauseToggle() then
        if game.state == "playing" then game.state = "paused"; audio.play("click")
        elseif game.state == "paused" then game.state = "playing"; audio.play("click") end
    end
    if game.state == "playing" then
        world.updateStars(dt, game.height)
        world.updatePlayer(dt, input.getState(), game.width, utils)
        world.shootTimer = world.shootTimer - dt
        if input.getState().shoot and world.shootTimer <= 0 then world.shoot(); world.shootTimer = math.max(0.04, world.player.fireRate); audio.play("shoot") end
        world.updateBullets(dt)
        world.spawnTimer = world.spawnTimer - dt
        if world.spawnTimer <= 0 then world.spawnEnemy(game.width, math.min(game.width, game.height), game.roundNum, rounds); world.spawnTimer = math.max(0.25, rounds.getSpawnRate(game.roundNum) / world.difficultyMultiplier) end
        world.updateEnemies(dt, game.width, game.height, utils, function() game.gameOver() end)
        world.checkBulletHits(utils, function(score) game.score = game.score + score; audio.play("hit") end, function() audio.play("explosion"); local ach = achievements.check({kills = 1, score = game.score, level = game.level, round = game.roundNum}); if ach then audio.play("achievement") end end)
        world.updatePowerups(dt, game.height, utils, function() audio.play("powerup"); local ach = achievements.check({powerup = true}); if ach then audio.play("achievement") end end)
        world.updateParticles(dt)
        world.difficultyMultiplier = 1 + game.score / 1000
        game.level = math.floor(game.score / 500) + 1
        if rounds.checkAdvance(game.score, game.roundNum) then
            game.roundNum = game.roundNum + 1
            game.state = "round_transition"
            audio.play("levelup")
            local ach = achievements.check({round = game.roundNum}); if ach then audio.play("achievement") end
            if world.stats.damageTaken == 0 then local ach2 = achievements.check({roundComplete = true}); if ach2 then audio.play("achievement") end end
            world.stats.damageTaken = 0
        end
        local ach = achievements.check({score = game.score, level = game.level}); if ach then audio.play("achievement") end
    elseif game.state == "menu" or game.state == "gameover" then
        world.player.engineGlow = world.player.engineGlow + dt * 3
    elseif game.state == "round_transition" then
        world.updateStars(dt, game.height)
        world.updateParticles(dt)
    end
end

function game.gameOver()
    game.state = "gameover"
    if game.score > game.highscore then game.highscore = game.score end
    game.modules.audio.play("gameover")
    game.modules.world.createExplosion(game.modules.world.player.x, game.modules.world.player.y, {1, 0.3, 0.1}, 60)
    game.save()
end

function game.persistState() game.save() end

function game.draw()
    local world = game.modules.world
    local ui = game.modules.ui
    local i18n = game.modules.i18n
    local assets = game.modules.assets
    local input = game.modules.input
    local dt = love.timer.getDelta()
    local target = game.canvas
    if target then love.graphics.setCanvas(target); love.graphics.clear(0.05, 0.05, 0.1, 1) end
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    world.drawStars()
    if game.state == "menu" then ui.drawMenu(game, i18n, assets, world, dt)
    elseif game.state == "language_menu" then ui.drawLanguageMenu(game, i18n, assets, dt)
    elseif game.state == "debug" then ui.drawDebugPanel(game, i18n, assets, game.modules.audio, input, game.saveData or {}, dt)
    elseif game.state == "ship_select" then ui.drawShipSelect(game, i18n, assets, game.modules.player, world, dt)
    elseif game.state == "settings" then ui.drawSettings(game, i18n, assets, game.modules.audio, dt)
    elseif game.state == "playing" or game.state == "paused" then
        world.drawPowerups(); world.drawEnemies(); world.drawBullets(); world.drawPlayer(); world.drawParticles()
        ui.drawHUD(game, world, i18n, assets)
        game.modules.achievements.draw(game.width, game.height, i18n, assets)
        if game.state == "paused" then ui.drawPaused(game, i18n, assets) end
    elseif game.state == "round_transition" then
        world.drawPowerups(); world.drawEnemies(); world.drawBullets(); world.drawParticles()
        ui.drawHUD(game, world, i18n, assets)
        ui.drawRoundTransition(game, i18n, assets, game.modules.rounds, dt)
    elseif game.state == "gameover" then
        world.drawPowerups(); world.drawEnemies(); world.drawBullets(); world.drawParticles(); ui.drawGameOver(game, i18n, assets, world)
    elseif game.state == "exit_prompt" then
        ui.drawExitPrompt(game, i18n, assets)
    end
    ui.drawExitButton(game, i18n, assets)
    ui.drawVirtualButtons(input, game.state, assets)
    if game.shader then game.shader:send("time", love.timer.getTime()) end
    if target then
        love.graphics.setCanvas()
        if game.shader then love.graphics.setShader(game.shader) end
        love.graphics.draw(target, 0, 0, 0, love.graphics.getWidth() / target:getWidth(), love.graphics.getHeight() / target:getHeight())
        love.graphics.setShader()
    end
end

function game.keypressed(key)
    local audio = game.modules.audio
    if key == "return" or key == "kpenter" then
        if game.state == "menu" or game.state == "gameover" then game.reset(); game.state = "playing"; audio.play("click")
        elseif game.state == "round_transition" then game.state = "playing"; audio.play("click")
        elseif game.state == "exit_prompt" then game.state = "menu"; game.pendingExit = false; audio.play("click") end
    elseif key == "p" then
        if game.state == "playing" then game.state = "paused"; audio.play("click")
        elseif game.state == "paused" then game.state = "playing"; audio.play("click") end
    elseif key == "escape" then
        if game.state ~= "menu" then game.state = "exit_prompt"; game.pendingExit = true; audio.play("click") end
    elseif key == "l" and game.state == "menu" then
        game.state = "language_menu"
    elseif key == "f1" then
        game.debugOpen = not game.debugOpen
        game.state = game.debugOpen and "debug" or "menu"
    elseif key == "left" or key == "a" then
        if game.state == "playing" then game.modules.input.setKey(key, true)
        elseif game.state == "ship_select" then game.cycleShip(-1); audio.play("click") end
    elseif key == "right" or key == "d" then
        if game.state == "playing" then game.modules.input.setKey(key, true)
        elseif game.state == "ship_select" then game.cycleShip(1); audio.play("click") end
    elseif key == "space" and game.state == "playing" then
        game.modules.input.setKey("space", true)
    elseif key == "f11" then
        game.isFullscreen = not game.isFullscreen
        love.window.setMode(0, 0, {fullscreen = game.isFullscreen, fullscreentype = "desktop", vsync = true, highdpi = true})
        game.width, game.height = love.graphics.getDimensions()
        game.resize(game.width, game.height)
    end
end

function game.keyreleased(key)
    if key == "left" or key == "a" or key == "right" or key == "d" or key == "space" or key == "p" then
        game.modules.input.setKey(key, false)
    end
end

function game.cycleShip(dir)
    local ui = game.modules.ui
    local order = game.modules.player.getOrder()
    ui.selectedShipIndex = ((ui.selectedShipIndex - 1 + dir) % #order) + 1
    ui.shipAnimOffset = dir * 80
    game.save()
end

function game.handlePointer(x, y, isPressed)
    local input = game.modules.input
    local ui = game.modules.ui
    local audio = game.modules.audio
    local result = input.handleTouch(x, y, isPressed, game.state)
    if result == "start" then
        if game.state == "menu" then game.reset(); game.state = "playing"; audio.play("click")
        elseif game.state == "gameover" then game.reset(); game.state = "playing"; audio.play("click") end
    elseif result == "resume" then
        if game.state == "paused" then game.state = "playing"; audio.play("click") end
    elseif result == "next_round" then
        if game.state == "round_transition" then game.state = "playing"; audio.play("click") end
    elseif result == false and isPressed then
        if game.state == "menu" then
            local mx, my = x, y
            local cx = game.width/2
            local btnW = math.min(340, game.width * 0.52)
            local btnH = math.min(60, game.height * 0.085)
            local btnGap = btnH * 1.55
            local startY = game.height/2 + math.min(game.width, game.height) * 0.1
            if utils.pointInRect(mx, my, cx - btnW/2, startY, btnW, btnH) then game.reset(); game.state = "playing"; audio.play("click")
            elseif utils.pointInRect(mx, my, cx - btnW/2, startY + btnGap, btnW, btnH) then game.state = "ship_select"; audio.play("click")
            elseif utils.pointInRect(mx, my, cx - btnW/2, startY + btnGap*2, btnW, btnH) then game.state = "settings"; audio.play("click")
            elseif utils.pointInRect(mx, my, cx - btnW/2, startY + btnGap*3, btnW, btnH) then game.state = "language_menu"; audio.play("click") end
            if ui.exitButton and utils.pointInRect(mx, my, ui.exitButton.x, ui.exitButton.y, ui.exitButton.w, ui.exitButton.h) then game.exit() end
        elseif game.state == "language_menu" then
            local choice = ui.getLanguageMenuChoice(game, x, y)
            if choice == false then
                game.state = "menu"
                audio.play("click")
            elseif choice then
                game.modules.i18n.setLang(choice)
                game.save()
                game.state = "menu"
                audio.play("click")
            end
        elseif game.state == "ship_select" then
            local cx = game.width/2
            local arrowSize = math.min(game.width, game.height) * 0.06
            local arrowY = game.height/2 - arrowSize
            local leftX = cx - game.width * 0.35
            local rightX = cx + game.width * 0.35
            if utils.pointInCircle(x, y, leftX, arrowY + arrowSize/2, arrowSize) then game.cycleShip(-1); audio.play("click")
            elseif utils.pointInCircle(x, y, rightX, arrowY + arrowSize/2, arrowSize) then game.cycleShip(1); audio.play("click") end
            local btnW = math.min(240, game.width * 0.4)
            local btnH = 50
            local selBtn = {x = cx - btnW/2, y = game.height - 150, w = btnW, h = btnH}
            local backBtn = {x = cx - btnW/2, y = game.height - 85, w = btnW, h = btnH}
            if utils.pointInRect(x, y, selBtn.x, selBtn.y, selBtn.w, selBtn.h) then local order = game.modules.player.getOrder(); game.modules.player.select(order[ui.selectedShipIndex]); game.state = "menu"; audio.play("click"); game.save()
            elseif utils.pointInRect(x, y, backBtn.x, backBtn.y, backBtn.w, backBtn.h) then game.state = "menu"; audio.play("click") end
        elseif game.state == "settings" then
            local cx = game.width/2
            local btnW = math.min(240, game.width * 0.4)
            local btnH = 50
            local backBtn = {x = cx - btnW/2, y = game.height - 92, w = btnW, h = btnH}
            if utils.pointInRect(x, y, backBtn.x, backBtn.y, backBtn.w, backBtn.h) then game.state = "menu"; audio.play("click") end
            local sliderId = input.checkSliderClick(x, y, ui.sliders)
            if sliderId then input.draggingSlider = sliderId end
        elseif game.state == "debug" then
            local action = ui.handleDebugClick(game, x, y, game.saveData or {})
            if action == "back" then game.debugOpen = false; game.state = "menu"
            elseif action == "save" then game.save() end
        elseif game.state == "exit_prompt" then
            local cx = game.width/2
            local cy = game.height/2
            local btnW = math.min(240, game.width * 0.35)
            local btnH = 50
            local yesBtn = {x = cx - btnW/2, y = cy + 20, w = btnW, h = btnH}
            local noBtn = {x = cx - btnW/2, y = cy + 90, w = btnW, h = btnH}
            if utils.pointInRect(x, y, yesBtn.x, yesBtn.y, yesBtn.w, yesBtn.h) then game.state = "menu"; game.pendingExit = false; audio.play("click")
            elseif utils.pointInRect(x, y, noBtn.x, noBtn.y, noBtn.w, noBtn.h) then game.state = "playing"; game.pendingExit = false; audio.play("click") end
        elseif game.state == "round_transition" then
            local cx = game.width/2
            local fs = math.min(game.width, game.height) * 0.08
            local btnW = math.min(220, game.width * 0.4)
            local btnH = 50
            local contBtn = {x = cx - btnW/2, y = game.height/2 + fs * 2.2, w = btnW, h = btnH}
            if utils.pointInRect(x, y, contBtn.x, contBtn.y, contBtn.w, contBtn.h) then game.state = "playing"; audio.play("click") end
        end
    end
end

function game.exit()
    love.event.quit()
end

function game.handlePointerMove(x, y)
    local input = game.modules.input
    local ui = game.modules.ui
    if game.state == "settings" and input.draggingSlider then
        input.updateSliderDrag(x, ui.sliders, input.draggingSlider)
        local val = ui.sliders[input.draggingSlider].value
        local audio = game.modules.audio
        if input.draggingSlider == "master" then audio.setMasterVolume(val)
        elseif input.draggingSlider == "sfx" then audio.setSfxVolume(val)
        elseif input.draggingSlider == "music" then audio.setMusicVolume(val) end
        game.save()
    elseif game.state == "debug" and input.draggingSlider then
        ui.updateDebugSlider(input.draggingSlider, x, game.saveData or {}, game.modules.audio)
        game.save()
    end
end

function game.resize(w, h)
    game.width = w; game.height = h
    game.canvas = love.graphics.newCanvas(w, h)
    game.modules.world.initStars(w, h)
    game.modules.input.init(w, h)
    if game.modules.world.player then
        game.modules.world.player.y = h - math.min(h * 0.12, 80)
        game.modules.world.player.x = math.max(game.modules.world.player.width/2, math.min(w - game.modules.world.player.width/2, game.modules.world.player.x))
    end
end

return game
