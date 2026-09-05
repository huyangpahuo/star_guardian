-- Love2D entry point. Forwards engine callbacks to the application core;
-- all game logic lives under src/.
local app = require("src.core.app")

local defaultErrorHandler = love.errorhandler

-- Log runtime errors to the save directory so failures are diagnosable
-- without a console; in smoke mode, quit immediately.
function love.errorhandler(msg)
    local text = tostring(msg) .. "\n" .. debug.traceback(nil, 2) .. "\n"
    pcall(function()
        love.filesystem.write("error_log.txt", os.date("%Y-%m-%d %H:%M:%S") .. " ===\n" .. text)
    end)
    if os.getenv("SG_SMOKE") == "1" then
        love.event.quit(1)
        return
    end
    return defaultErrorHandler(msg)
end

function love.load()
    app.init()
end

function love.update(dt)
    local ok, err = xpcall(app.update, debug.traceback, dt)
    if not ok then app.reportError(err) end
end

function love.draw()
    local ok, err = xpcall(app.draw, debug.traceback)
    if not ok then app.reportError(err) end
end

-- Extra error capture outside the engine's handler so failures in the
-- draw path are always logged before surfacing.
function app.reportError(err)
    pcall(function()
        love.filesystem.write("error_log.txt", os.date("%Y-%m-%d %H:%M:%S") .. " ===\n" .. tostring(err) .. "\n")
    end)
    error(err, 0)
end

function love.keypressed(key, scancode, isrepeat)
    app.keypressed(key, scancode, isrepeat)
end

-- Unified pointer events: mouse (when not a synthesized touch) and touch
-- both feed the same scene handlers; touch also drives the virtual buttons.
function love.mousepressed(x, y, button, istouch)
    if button == 1 and not istouch then
        app.pointerpressed(x, y)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if not istouch then
        app.pointermoved(x, y)
    end
end

function love.mousereleased(x, y, button, istouch)
    if button == 1 and not istouch then
        app.pointerreleased(x, y)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    app.touchpressed(id, x, y)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    app.touchmoved(id, x, y)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    app.touchreleased(id, x, y)
end

function love.resize(w, h)
    app.resize(w, h)
    -- repaint immediately so content scales live while dragging the edge
    app.redrawNow()
end

function love.quit()
    app.shutdown()
end
