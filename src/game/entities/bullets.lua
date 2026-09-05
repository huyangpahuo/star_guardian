-- Player bullets. Spawn pattern depends on the equipped ship skill
-- (double / penetrate / default); motion is straight with a fixed angle.
local bullets = {}

function bullets.spawn(list, player)
    local bw = math.max(4, player.width * 0.15)
    local bh = math.max(8, player.height * 0.35)
    local function add(x, y, color, overrides)
        local b = {
            x = x, y = y, width = bw, height = bh,
            color = color, damage = player.damage,
            penetrate = 0, angle = 0,
        }
        if overrides then
            for k, v in pairs(overrides) do b[k] = v end
        end
        list[#list + 1] = b
    end
    if player.skill == "double" then
        add(player.x - 8, player.y - player.height / 2, {0.4, 0.9, 1}, {angle = -0.08})
        add(player.x + 8, player.y - player.height / 2, {0.4, 0.9, 1}, {angle = 0.08})
    elseif player.skill == "penetrate" then
        add(player.x, player.y - player.height / 2, {1, 0.4, 0.6},
            {width = bw * 1.3, height = bh * 1.2, penetrate = 3})
    else
        add(player.x, player.y - player.height / 2, {0.4, 0.9, 1})
    end
end

function bullets.update(list, dt, speed, w)
    for i = #list, 1, -1 do
        local b = list[i]
        b.y = b.y - speed * dt
        if b.angle ~= 0 then b.x = b.x + b.angle * speed * dt end
        if b.y < -20 or b.x < -20 or b.x > w + 20 then table.remove(list, i) end
    end
end

function bullets.draw(list)
    for _, b in ipairs(list) do
        love.graphics.setColor(b.color[1], b.color[2], b.color[3])
        love.graphics.rectangle("fill", b.x - b.width / 2, b.y - b.height / 2, b.width, b.height)
        love.graphics.setColor(b.color[1], b.color[2], b.color[3], 0.3)
        love.graphics.rectangle("fill", b.x - b.width / 2 - 2, b.y - b.height / 2 - 2, b.width + 4, b.height + 4)
    end
end

return bullets
