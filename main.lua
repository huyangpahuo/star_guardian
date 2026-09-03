local i18n = require("i18n")
local assets = require("assets")
local utils = require("utils")
local audio = require("audio")
local player = require("player")
local world = require("world")
local input = require("input")
local ui = require("ui")
local achievements = require("achievements")
local rounds = require("rounds")
local game = require("game")
local meta = require("meta")
local app = require("app")

function love.load()
    i18n.autoDetect()
    assets.init()
    game.init({i18n = i18n, assets = assets, utils = utils, audio = audio, player = player, world = world, input = input, ui = ui, achievements = achievements, rounds = rounds, meta = meta, app = app})
end

function love.update(dt) game.update(dt) end
function love.draw() game.draw() end
function love.keypressed(key) game.keypressed(key) end
function love.keyreleased(key) game.keyreleased(key) end
function love.touchpressed(id, x, y, dx, dy, pressure) game.handlePointer(x, y, true) end
function love.touchmoved(id, x, y, dx, dy, pressure) game.handlePointerMove(x, y); game.handlePointer(x, y, true) end
function love.touchreleased(id, x, y, dx, dy, pressure) game.modules.input.resetTouch(); game.handlePointer(x, y, false) end
function love.mousepressed(x, y, button, istouch) if not istouch then game.handlePointer(x, y, true) end end
function love.mousemoved(x, y, dx, dy, istouch) if not istouch then game.handlePointerMove(x, y) end end
function love.mousereleased(x, y, button, istouch) if not istouch then game.modules.input.resetTouch(); game.handlePointer(x, y, false) end end
function love.resize(w, h) game.resize(w, h) end
