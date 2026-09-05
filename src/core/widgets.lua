-- Immediate-mode UI helpers. Every interactive widget draws itself AND
-- registers its hit area into the current frame's layout table, so the
-- click zone can never drift from what is actually on screen.
-- Scenes pass their frame's `layout` in; pointer events call widgets.hitTest
-- on that same table.
local utils = require("src.core.utils")

local widgets = {}

function widgets.register(layout, id, hit) layout[id] = hit end

function widgets.hitTest(layout, x, y)
    for id, hit in pairs(layout) do
        if hit.kind == "circle" then
            if utils.pointInCircle(x, y, hit.cx, hit.cy, hit.r) then return id end
        elseif utils.pointInRect(x, y, hit.x, hit.y, hit.w, hit.h) then
            return id
        end
    end
    return nil
end

-- Pointer x mapped to a 0..1 slider value given the widget's hit area.
function widgets.sliderRatio(hit, x)
    return utils.clamp((x - hit.x) / hit.w, 0, 1)
end

local function isHovered(ctx, hit)
    local p = ctx.input.pointer
    if hit.kind == "circle" then
        return utils.pointInCircle(p.x, p.y, hit.cx, hit.cy, hit.r)
    end
    return utils.pointInRect(p.x, p.y, hit.x, hit.y, hit.w, hit.h)
end

-- Draws a button and registers its hit area. opts: {color, pressed, disabled}
function widgets.button(ctx, layout, id, text, x, y, w, h, opts)
    opts = opts or {}
    local color = opts.color or ctx.theme.colors.secondary
    local hit = {kind = "rect", x = x, y = y, w = w, h = h}
    local hovered = not opts.disabled and isHovered(ctx, hit)
    local brightness = opts.pressed and 1.25 or (hovered and 1.08 or 1.0)
    local alpha = opts.disabled and 0.4 or 0.86
    local g = love.graphics
    g.setColor(color[1] * brightness, color[2] * brightness, color[3] * brightness, alpha)
    g.rectangle("fill", x, y, w, h, 12, 12)
    g.setColor(1, 1, 1, 0.18)
    g.rectangle("line", x, y, w, h, 12, 12)
    local fs = math.floor(h * 0.38)
    ctx.assets.setFont(fs)
    g.setColor(1, 1, 1, opts.disabled and 0.6 or 1)
    g.print(text, x + w / 2 - g.getFont():getWidth(text) / 2, y + h / 2 - g.getFont():getHeight() / 2)
    layout[id] = hit
    return hit
end

-- Horizontal slider; the whole track is the hit area.
function widgets.slider(ctx, layout, id, x, y, w, h, label, value)
    local g = love.graphics
    local labelSize = math.floor(h * 0.9)
    ctx.assets.setFont(labelSize)
    g.setColor(0.7, 0.8, 0.9)
    g.print(label, x, y - labelSize - 4)
    g.setColor(0.15, 0.18, 0.25)
    g.rectangle("fill", x, y + h / 2 - 3, w, 6, 3, 3)
    g.setColor(0.3, 0.7, 1)
    g.rectangle("fill", x, y + h / 2 - 3, w * value, 6, 3, 3)
    local knobX = x + w * value
    local knobR = h * 0.5
    g.setColor(0.4, 0.8, 1)
    g.circle("fill", knobX, y + h / 2, knobR)
    g.setColor(1, 1, 1, 0.5)
    g.circle("line", knobX, y + h / 2, knobR)
    g.setColor(0.8, 0.9, 1)
    ctx.assets.setFont(math.floor(labelSize * 0.8))
    local valText = math.floor(value * 100) .. "%"
    g.print(valText, x + w + 12, y + h / 2 - labelSize * 0.4)
    layout[id] = {kind = "slider", x = x, y = y, w = w, h = h, knobX = knobX, knobY = y + h / 2}
    return layout[id]
end

function widgets.statBar(x, y, w, h, label, value, color, assets)
    assets.setFont(math.floor(h * 1.2))
    love.graphics.setColor(0.7, 0.8, 0.9)
    love.graphics.print(label, x, y - h * 1.5)
    love.graphics.setColor(0.15, 0.18, 0.25)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", x, y, w * value, h, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

-- Animated fractal backdrop shared by all menu-style screens.
function widgets.backdrop(w, h, t, dim)
    local g = love.graphics
    for i = 1, 6 do
        local a = 0.04 + i * 0.015
        local r = math.min(w, h) * (0.18 + i * 0.07)
        local x = w * 0.5 + math.sin(t * 0.4 + i) * w * 0.08
        local y = h * 0.42 + math.cos(t * 0.35 + i * 1.3) * h * 0.04
        g.setColor(0.15 + i * 0.04, 0.22 + i * 0.03, 0.35 + i * 0.02, a)
        g.circle("fill", x, y, r, 48)
    end
    g.setColor(0.06, 0.08, 0.14, dim or 0.38)
    g.rectangle("fill", 0, 0, w, h)
end

function widgets.centerText(text, cx, y, size, color, assets)
    assets.setFont(math.floor(size))
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.print(text, cx - love.graphics.getFont():getWidth(text) / 2, y)
end

return widgets
