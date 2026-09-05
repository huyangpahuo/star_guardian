-- Power-up pickups: spawn on kills, drift down, apply an effect on collect.
local utils = require("src.core.utils")

local powerups = {}

powerups.TYPES = {
    health = {color = {0.2, 1, 0.3}},
    speed  = {color = {0.3, 0.6, 1}},
    rapid  = {color = {1, 0.8, 0.2}},
}

function powerups.spawn(list, x, y, baseSize)
    local names = {"health", "speed", "rapid"}
    local kind = names[math.random(1, #names)]
    list[#list + 1] = {
        x = x, y = y,
        width = baseSize * 0.035, height = baseSize * 0.035,
        type = kind, color = powerups.TYPES[kind].color, pulse = 0,
    }
end

-- onCollect(type) fires for pickups the player grabbed; expired pickups
-- are silently removed.
function powerups.update(list, dt, h, player, onCollect)
    for i = #list, 1, -1 do
        local p = list[i]
        p.y = p.y + 80 * dt
        p.pulse = p.pulse + dt * 4
        if utils.checkCollision(p, player) then
            powerups.apply(p.type, player)
            if onCollect then onCollect(p.type) end
            table.remove(list, i)
        elseif p.y > h + 20 then
            table.remove(list, i)
        end
    end
end

function powerups.apply(kind, player)
    if kind == "health" then
        player.hp = math.min(player.maxHp, player.hp + 30)
    elseif kind == "speed" then
        player.speed = math.min(player.maxSpeed or 900, player.speed + 50)
    elseif kind == "rapid" then
        player.fireRate = math.max(0.05, player.fireRate - 0.02)
    end
end

function powerups.draw(list)
    for _, p in ipairs(list) do
        local pulse = 1 + math.sin(p.pulse) * 0.2
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], 0.8)
        love.graphics.circle("fill", p.x, p.y, (p.width / 2) * pulse)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("line", p.x, p.y, (p.width / 2) * pulse + 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        local s = p.width * 0.25
        if p.type == "health" then
            love.graphics.rectangle("fill", p.x - s * 0.3, p.y - s, s * 0.6, s * 2)
            love.graphics.rectangle("fill", p.x - s, p.y - s * 0.3, s * 2, s * 0.6)
        elseif p.type == "speed" then
            love.graphics.polygon("fill", p.x + s * 0.5, p.y - s, p.x - s * 0.3, p.y, p.x + s * 0.2, p.y, p.x - s * 0.5, p.y + s, p.x + s * 0.3, p.y, p.x - s * 0.2, p.y)
        else -- rapid
            love.graphics.polygon("fill", p.x - s * 0.5, p.y - s * 0.6, p.x, p.y, p.x - s * 0.5, p.y + s * 0.6)
            love.graphics.polygon("fill", p.x, p.y - s * 0.6, p.x + s * 0.5, p.y, p.x, p.y + s * 0.6)
        end
    end
end

return powerups
