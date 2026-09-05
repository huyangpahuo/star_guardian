-- Composition root: builds every service, wires the scene router, and
-- exposes the small context API that scenes receive everywhere.
local utils = require("src.core.utils")
local theme = require("src.core.theme")
local widgets = require("src.core.widgets")
local i18n = require("src.core.i18n")
local assets = require("src.core.assets")
local audio = require("src.core.audio")
local input = require("src.core.input")
local save = require("src.core.save")
local session = require("src.core.session")
local routerModule = require("src.core.router")
local mcp_bridge = require("src.core.mcp_bridge")
local ships = require("src.game.ships")
local rounds = require("src.game.rounds")
local achievements = require("src.game.achievements")
local world = require("src.game.world")

local app = {}

local function buildScenes()
    return {
        menu = require("src.scenes.menu"),
        ship_select = require("src.scenes.ship_select"),
        settings = require("src.scenes.settings"),
        language = require("src.scenes.language"),
        playing = require("src.scenes.playing"),
        paused = require("src.scenes.paused"),
        round_transition = require("src.scenes.round_transition"),
        gameover = require("src.scenes.gameover"),
        exit_prompt = require("src.scenes.exit_prompt"),
        debug = require("src.scenes.debug"),
    }
end

function app.init()
    local osName = love.system.getOS()
    local desktop = not (osName == "Android" or osName == "iOS")

    -- persistence + language
    save.init()
    i18n.autoDetect()
    if save.data.lang then i18n.setLang(save.data.lang) end
    i18n.onLangChange(function(lang) assets.setLanguage(lang) end)
    assets.setLanguage(i18n.lang)
    assets.init()

    -- audio volumes from the profile
    audio.init()
    audio.setMasterVolume(save.data.audio.master or 1)
    audio.setSfxVolume(save.data.audio.sfx or 1)
    audio.setMusicVolume(save.data.audio.music or 0.4)

    local ctx = {}
    ctx.utils, ctx.theme, ctx.widgets = utils, theme, widgets
    ctx.i18n, ctx.assets, ctx.audio = i18n, assets, audio
    ctx.input, ctx.save, ctx.session = input, save, session
    ctx.ships, ctx.rounds, ctx.achievements = ships, rounds, achievements
    ctx.world = world
    ctx.isMobile = not desktop
    ctx.time = 0
    app.ctx = ctx

    local w, h = love.graphics.getDimensions()
    ctx.w, ctx.h = w, h

    achievements.init(save.data.achievements)
    world.init(w, h)
    input.init(w, h)
    session.highscore = save.data.highscore

    -- restore fullscreen preference once (desktop only)
    if desktop and save.data.fullscreen then
        love.window.setFullscreen(true, "desktop")
    end

    ctx.router = routerModule.new(buildScenes(), ctx)
    ctx.router:gotoScene("menu")

    -- small helpers shared by scenes
    ctx.setLanguage = function(code)
        i18n.setLang(code)
        save.data.lang = i18n.lang
        save.write()
    end
    ctx.persistAchievements = function()
        save.data.achievements = achievements.unlockedIds()
        save.write()
    end
    ctx.toggleFullscreen = function()
        if not desktop then return end
        local fs = not love.window.getFullscreen()
        love.window.setFullscreen(fs, "desktop")
        save.data.fullscreen = fs
        save.write()
    end

    -- post-processing shader over the whole frame
    ctx.canvas = love.graphics.newCanvas(w, h)
    if love.filesystem.getInfo("resources/shaders/post.glsl") then
        local ok, shader = pcall(love.graphics.newShader, love.filesystem.read("resources/shaders/post.glsl"))
        if ok then app.shader = shader end
    end

    -- optional MCP bridge (only when MCP_PORT is set)
    mcp_bridge.init()
    mcp_bridge.setObjectGetter(function()
        return {
            session = session,
            world = world,
            player = world.player,
            profile = save.data,
        }
    end)

    if os.getenv("SG_SMOKE") == "1" then
        app.smoke = require("src.core.smoke").start(ctx)
    end
end

function app.update(dt)
    local ctx = app.ctx
    ctx.time = ctx.time + dt
    ctx.w, ctx.h = love.graphics.getDimensions()
    input.update()
    ctx.router:update(dt)
    achievements.update(dt)
    audio.update()
    mcp_bridge.update()
    if app.smoke then
        -- capture smoke errors directly so diagnosis never depends on the
        -- engine's error screen
        local ok, err = xpcall(app.smoke.tick, debug.traceback)
        if not ok then
            pcall(function() love.filesystem.write("smoke_error.txt", tostring(err) .. "\n") end)
            love.event.quit(2)
        end
    end
end

function app.draw()
    local ctx = app.ctx
    local target = ctx.canvas
    if target then
        love.graphics.setCanvas(target)
        love.graphics.clear(theme.colors.bg[1], theme.colors.bg[2], theme.colors.bg[3], 1)
    end
    ctx.router:draw()
    if ctx.session.runActive then
        ctx.achievements.draw(ctx.w, ctx.h, ctx.i18n, ctx.assets)
    end
    if target then
        love.graphics.setCanvas()
        if app.shader then
            app.shader:send("time", love.timer.getTime())
            love.graphics.setShader(app.shader)
        end
        love.graphics.draw(target, 0, 0, 0,
            love.graphics.getWidth() / target:getWidth(),
            love.graphics.getHeight() / target:getHeight())
        love.graphics.setShader()
    end
end

-- F11 / F1 are global hotkeys; everything else goes to the top scene.
function app.keypressed(key, scancode, isrepeat)
    if isrepeat then return end
    local ctx = app.ctx
    if key == "f11" then
        ctx.toggleFullscreen()
        return
    elseif key == "f1" then
        if ctx.router:currentName() == "debug" then
            ctx.router:pop()
        else
            ctx.router:push("debug")
        end
        return
    end
    ctx.router:keypressed(key)
end

function app.pointerpressed(x, y)
    local ctx = app.ctx
    input.setPointer(x, y)
    ctx.router:pointerpressed(x, y)
end

function app.pointerreleased(x, y)
    local ctx = app.ctx
    input.setPointer(x, y)
    ctx.router:pointerreleased(x, y)
end

function app.pointermoved(x, y)
    local ctx = app.ctx
    input.setPointer(x, y)
    ctx.router:pointermoved(x, y)
end

function app.touchpressed(id, x, y)
    input.touchpressed(id, x, y)
    app.pointerpressed(x, y)
end

function app.touchmoved(id, x, y)
    input.touchmoved(id, x, y)
    app.pointermoved(x, y)
end

function app.touchreleased(id, x, y)
    input.touchreleased(id)
    app.pointerreleased(x, y)
end

function app.resize(w, h)
    local ctx = app.ctx
    ctx.w, ctx.h = w, h
    ctx.canvas = love.graphics.newCanvas(w, h)
    input.resize(w, h)
    world.onResize(w, h)
end

function app.shutdown()
    save.write()
    mcp_bridge.shutdown()
end

return app
