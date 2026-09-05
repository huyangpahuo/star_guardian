-- Input normalization. Keyboard, mouse and touch all collapse into:
--   * input.actions    - continuous state (move / shoot) consumed by gameplay
--   * input.pointer    - cursor position for hover and UI hit tests
--   * input.touches    - multi-touch map (finger id -> virtual button)
--   * pauseRequested   - edge-triggered flag from the virtual pause button
-- Scenes receive high-level events; they never poll devices themselves.
local utils = require("src.core.utils")

local input = {
    pointer = {x = 0, y = 0},
    actions = {left = false, right = false, shoot = false},
    buttons = {},
    touches = {},
    showTouchControls = false,
    isMobile = false,
    pauseRequested = false,
}

function input.init(w, h)
    local osName = love.system.getOS()
    input.isMobile = (osName == "Android" or osName == "iOS")
    input.showTouchControls = input.isMobile
    input.pointer.x, input.pointer.y = w / 2, h / 2
    input.layoutButtons(w, h)
end

function input.layoutButtons(w, h)
    local margin = math.min(w, h) * 0.04
    local s = math.min(w, h) * 0.11
    input.buttons = {
        left  = {x = margin + s * 0.5,     y = h - margin - s * 0.5, size = s,        label = "←", color = {0.2, 0.5, 0.8}},
        right = {x = margin + s * 2.0,     y = h - margin - s * 0.5, size = s,        label = "→", color = {0.2, 0.5, 0.8}},
        shoot = {x = w - margin - s * 0.8, y = h - margin - s * 0.8, size = s * 1.3,  label = "●", color = {0.9, 0.3, 0.2}},
        pause = {x = w - margin - s * 0.4, y = margin + s * 0.4,     size = s * 0.65, label = "II", color = {0.6, 0.6, 0.7}},
    }
end

function input.resize(w, h) input.layoutButtons(w, h) end

function input.setPointer(x, y) input.pointer.x, input.pointer.y = x, y end

function input.update()
    if input.showTouchControls then
        local pressed = {}
        for _, name in pairs(input.touches) do pressed[name] = true end
        input.actions.left = pressed.left or false
        input.actions.right = pressed.right or false
        input.actions.shoot = pressed.shoot or false
    else
        local kb = love.keyboard
        input.actions.left = kb.isDown("a") or kb.isDown("left")
        input.actions.right = kb.isDown("d") or kb.isDown("right")
        input.actions.shoot = kb.isDown("space") or love.mouse.isDown(1)
    end
end

local function buttonAt(x, y)
    for name, btn in pairs(input.buttons) do
        if utils.pointInCircle(x, y, btn.x, btn.y, btn.size / 2) then return name end
    end
    return nil
end

-- Multi-touch: each finger maps to at most one virtual button and fingers
-- can move between buttons without breaking the others.
function input.touchpressed(id, x, y)
    input.setPointer(x, y)
    local name = buttonAt(x, y)
    if name == "pause" then input.pauseRequested = true end
    if name then input.touches[id] = name end
end

function input.touchmoved(id, x, y)
    input.setPointer(x, y)
    input.touches[id] = buttonAt(x, y)
end

function input.touchreleased(id)
    input.touches[id] = nil
end

function input.isButtonPressed(name)
    for _, n in pairs(input.touches) do
        if n == name then return true end
    end
    return false
end

function input.consumePauseRequest()
    local r = input.pauseRequested
    input.pauseRequested = false
    return r
end

-- Virtual buttons are drawn by the gameplay scene on touch devices.
function input.drawButtons(assets)
    if not input.showTouchControls then return end
    local g = love.graphics
    for name, btn in pairs(input.buttons) do
        local alpha = input.isButtonPressed(name) and 0.7 or 0.3
        g.setColor(btn.color[1], btn.color[2], btn.color[3], alpha)
        g.circle("fill", btn.x, btn.y, btn.size / 2)
        g.setColor(1, 1, 1, 0.35)
        g.circle("line", btn.x, btn.y, btn.size / 2)
        g.setColor(1, 1, 1, 0.85)
        local ls = btn.size * 0.45
        assets.setFont(math.floor(ls))
        g.print(btn.label, btn.x - g.getFont():getWidth(btn.label) / 2, btn.y - ls * 0.4)
    end
end

return input
