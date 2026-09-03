local utils = require("utils")

local input = {
    state = {left = false, right = false, shoot = false, pause = false},
    buttons = {},
    lastPause = false,
    draggingSlider = nil,
    showTouchControls = false,
    isDesktop = true,
}

function input.init(screenWidth, screenHeight)
    local margin = math.min(screenWidth, screenHeight) * 0.04
    local btnSize = math.min(screenWidth, screenHeight) * 0.11
    local osName = love.system.getOS()
    input.isDesktop = not (osName == "Android" or osName == "iOS")
    input.showTouchControls = not input.isDesktop
    input.buttons = {
        left = {x = margin + btnSize * 0.5, y = screenHeight - margin - btnSize * 0.5, size = btnSize, label = "←", color = {0.2, 0.5, 0.8, 0.35}},
        right = {x = margin + btnSize * 2.0, y = screenHeight - margin - btnSize * 0.5, size = btnSize, label = "→", color = {0.2, 0.5, 0.8, 0.35}},
        shoot = {x = screenWidth - margin - btnSize * 0.8, y = screenHeight - margin - btnSize * 0.8, size = btnSize * 1.3, label = "●", color = {0.9, 0.3, 0.2, 0.35}},
        pause = {x = screenWidth - margin - btnSize * 0.4, y = margin + btnSize * 0.4, size = btnSize * 0.65, label = "II", color = {0.6, 0.6, 0.7, 0.35}},
    }
end

function input.update()
    if input.isDesktop then
        input.state.left = love.keyboard.isDown("a")
        input.state.right = love.keyboard.isDown("d")
        input.state.shoot = love.mouse.isDown(1)
        input.state.pause = false
    end
end

function input.handleTouch(x, y, isPressed, gameState)
    input.draggingSlider = nil
    if not input.showTouchControls then
        return false
    end
    if isPressed then
        if gameState == "playing" then
            input.state.left = false; input.state.right = false; input.state.shoot = false; input.state.pause = false
            for name, btn in pairs(input.buttons) do
                if utils.pointInCircle(x, y, btn.x, btn.y, btn.size/2) then
                    input.state[name] = true
                    return true
                end
            end
            return false
        end
        if gameState == "gameover" then
            if y < love.graphics.getHeight() * 0.85 then return "start" end
        end
        if gameState == "paused" then return "resume"
        elseif gameState == "round_transition" then return "next_round" end
    else
        input.state.left = false; input.state.right = false; input.state.shoot = false; input.state.pause = false
    end
    return false
end

function input.checkPauseToggle()
    local current = input.state.pause
    local triggered = current and not input.lastPause
    input.lastPause = current
    return triggered
end

function input.resetTouch()
    input.state.left = false; input.state.right = false; input.state.shoot = false; input.state.pause = false; input.lastPause = false
end

function input.setKey(key, isDown)
    if key == "left" or key == "a" then input.state.left = isDown
    elseif key == "right" or key == "d" then input.state.right = isDown
    elseif key == "space" then input.state.shoot = isDown
    elseif key == "p" then input.state.pause = isDown end
end

function input.getState() return input.state end
function input.getButtons() return input.buttons end
function input.isPressed(name) return input.state[name] or false end
function input.checkSliderClick(x, y, sliders) for id, s in pairs(sliders) do local knobR = s.height * 0.6; if utils.pointInCircle(x, y, s.knobX, s.knobY, knobR * 1.5) then return id end end end
function input.updateSliderDrag(x, sliders, sliderId) if not sliderId or not sliders[sliderId] then return end; local s = sliders[sliderId]; local relX = utils.clamp(x, s.x, s.x + s.width); local ratio = (relX - s.x) / s.width; s.value = ratio; s.knobX = relX end

return input
