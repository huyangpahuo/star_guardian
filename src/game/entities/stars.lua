-- Starfield: stateless helpers operating on a plain array owned by world.
local stars = {}

function stars.init(list, w, h)
    for i = #list, 1, -1 do list[i] = nil end
    local count = math.floor((w * h) / 3500)
    for i = 1, count do
        list[i] = {
            x = math.random(0, w), y = math.random(0, h),
            size = math.random(1, 3), speed = math.random(10, 80),
            brightness = math.random(150, 255),
        }
    end
    return list
end

function stars.update(list, dt, w, h)
    for _, s in ipairs(list) do
        s.y = s.y + s.speed * dt
        if s.y > h then
            s.y = 0
            s.x = math.random(0, w)
        end
    end
end

function stars.draw(list)
    for _, s in ipairs(list) do
        local b = s.brightness / 255
        love.graphics.setColor(b, b, math.min(1, b * 1.2))
        love.graphics.circle("fill", s.x, s.y, s.size * 0.6)
    end
end

return stars
