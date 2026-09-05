-- Enemy archetypes and behavior. Sizes/speeds are fractions of a base
-- screen dimension; movement only — collision and removal live in world.
local utils = require("src.core.utils")

local enemies = {}

enemies.TYPES = {
    scout   = {w = 0.045, h = 0.045, hp = 1, speed = 0.18, score = 10, color = {1, 0.3, 0.3},   sway = false},
    fighter = {w = 0.055, h = 0.055, hp = 2, speed = 0.12, score = 25, color = {1, 0.6, 0.2},   sway = true, swayAmount = 0.08, swaySpeed = 3},
    tank    = {w = 0.065, h = 0.065, hp = 5, speed = 0.07, score = 50, color = {0.8, 0.2, 0.8}, sway = true, swayAmount = 0.04, swaySpeed = 1.5},
    speeder = {w = 0.040, h = 0.055, hp = 1, speed = 0.30, score = 40, color = {0.2, 0.8, 1},   sway = false},
}

function enemies.spawn(list, etype, w, baseSize, difficulty, speedMult)
    local t = enemies.TYPES[etype] or enemies.TYPES.scout
    list[#list + 1] = {
        x = math.random(math.floor(t.w * baseSize), math.max(1, math.floor(w - t.w * baseSize))),
        y = -50,
        width = t.w * baseSize,
        height = t.h * baseSize,
        hp = t.hp, maxHp = t.hp,
        speed = t.speed * baseSize * difficulty * speedMult,
        score = t.score,
        color = t.color,
        rotation = 0,
        rotSpeed = math.random(-2, 2),
        sway = t.sway,
        swayAmount = (t.swayAmount or 0) * baseSize,
        swaySpeed = t.swaySpeed or 0,
        swayOffset = math.random() * 10,
        type = etype,
    }
end

function enemies.update(list, dt, w)
    for _, e in ipairs(list) do
        e.y = e.y + e.speed * dt
        e.rotation = e.rotation + e.rotSpeed * dt
        if e.sway then
            e.x = e.x + math.sin(love.timer.getTime() * e.swaySpeed + e.swayOffset) * e.swayAmount * dt
        end
        e.x = utils.clamp(e.x, e.width / 2, w - e.width / 2)
    end
end

function enemies.draw(list)
    for _, e in ipairs(list) do
        love.graphics.push()
        love.graphics.translate(e.x, e.y)
        love.graphics.rotate(e.rotation)
        if e.type == "scout" then
            love.graphics.setColor(e.color[1], e.color[2], e.color[3])
            love.graphics.polygon("fill", 0, -e.height / 2, e.width / 2, 0, 0, e.height / 2, -e.width / 2, 0)
            love.graphics.setColor(1, 0.5, 0.5, 0.5)
            love.graphics.polygon("line", 0, -e.height / 2, e.width / 2, 0, 0, e.height / 2, -e.width / 2, 0)
        elseif e.type == "fighter" then
            love.graphics.setColor(e.color[1], e.color[2], e.color[3])
            love.graphics.polygon("fill", 0, e.height / 2, e.width / 2, -e.height / 3, 0, -e.height / 2, -e.width / 2, -e.height / 3)
            love.graphics.setColor(1, 0.7, 0.3, 0.6)
            love.graphics.polygon("line", 0, e.height / 2, e.width / 2, -e.height / 3, 0, -e.height / 2, -e.width / 2, -e.height / 3)
        elseif e.type == "tank" then
            love.graphics.setColor(e.color[1], e.color[2], e.color[3])
            local r = e.width / 2
            love.graphics.polygon("fill", r, 0, r / 2, r * 0.866, -r / 2, r * 0.866, -r, 0, -r / 2, -r * 0.866, r / 2, -r * 0.866)
            love.graphics.setColor(0.9, 0.4, 0.9, 0.5)
            love.graphics.polygon("line", r, 0, r / 2, r * 0.866, -r / 2, r * 0.866, -r, 0, -r / 2, -r * 0.866, r / 2, -r * 0.866)
        else -- speeder
            love.graphics.setColor(e.color[1], e.color[2], e.color[3])
            love.graphics.polygon("fill", 0, -e.height / 2, e.width / 3, 0, 0, e.height / 2, -e.width / 3, 0)
        end
        if e.hp < e.maxHp then
            love.graphics.rotate(-e.rotation)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", -e.width / 2, -e.height / 2 - 10, e.width, 4)
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.rectangle("fill", -e.width / 2, -e.height / 2 - 10, e.width * (e.hp / e.maxHp), 4)
        end
        love.graphics.pop()
    end
end

return enemies
