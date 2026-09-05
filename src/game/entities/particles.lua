-- Particle bursts (explosions, hits, pickups): stateless helpers over an
-- array owned by world.
local particles = {}

function particles.burst(list, x, y, color, count)
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 250)
        list[#list + 1] = {
            x = x, y = y,
            vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
            life = math.random(0.3, 0.8), maxLife = 0.8,
            size = math.random(2, 5), color = color,
        }
    end
end

function particles.update(list, dt)
    for i = #list, 1, -1 do
        local p = list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.vy = p.vy + 50 * dt
        if p.life <= 0 then table.remove(list, i) end
    end
end

function particles.draw(list)
    for _, p in ipairs(list) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
end

return particles
