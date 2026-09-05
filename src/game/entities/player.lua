-- Player ship entity: runtime state, per-frame update, and the shared ship
-- renderer. The renderer also draws throwaway preview entities for menus,
-- which is why previews never need to touch the live game world.
local utils = require("src.core.utils")

local player = {}

function player.create(w, h)
    local base = math.min(w, h)
    return {
        x = w / 2,
        y = h - math.min(h * 0.12, 80),
        width = base * 0.055,
        height = base * 0.055,
        speed = 350,
        maxSpeed = h * 0.8,
        hp = 100, maxHp = 100,
        fireRate = 0.09,
        bulletSpeed = base * 0.95,
        damage = 1,
        invincible = 0,
        engineGlow = 0,
        shipType = "striker",
        skill = "none",
        color = {0.3, 0.7, 1},
    }
end

-- Copy catalog stats onto the live entity (position/size are preserved).
function player.applyConfig(p, cfg, h)
    p.hp = cfg.hp
    p.maxHp = cfg.maxHp
    p.speed = cfg.speed
    p.maxSpeed = h * 0.8
    p.fireRate = cfg.fireRate
    p.damage = cfg.damage
    p.bulletSpeed = cfg.bulletSpeed
    p.shipType = cfg.id
    p.skill = cfg.skill
    p.color = cfg.color
    p.y = h - math.min(h * 0.12, 80)
end

function player.update(p, dt, actions, w)
    local move = 0
    if actions.left then move = move - 1 end
    if actions.right then move = move + 1 end
    if move ~= 0 then p.x = p.x + move * p.speed * dt end
    p.x = utils.clamp(p.x, p.width / 2, w - p.width / 2)
    p.engineGlow = p.engineGlow + dt * 10
    if p.invincible > 0 then p.invincible = p.invincible - dt end
end

-- Build a lightweight entity for menus/previews without touching the game.
function player.preview(cfg, x, y, size)
    return {
        x = x, y = y, width = size, height = size,
        hp = cfg.hp, maxHp = cfg.maxHp,
        fireRate = cfg.fireRate, damage = cfg.damage, bulletSpeed = cfg.bulletSpeed,
        invincible = 0,
        engineGlow = love.timer.getTime() * 3,
        shipType = cfg.id, skill = cfg.skill, color = cfg.color,
    }
end

function player.draw(p)
    if p.invincible > 0 and math.sin(love.timer.getTime() * 15) <= 0 then return end
    local c = p.color or {0.3, 0.7, 1}
    local g = love.graphics
    g.push()
    g.translate(p.x, p.y)
    local fh = 15 + math.sin(p.engineGlow) * 5
    g.setColor(c[1] * 0.6, c[2] * 0.8, 1, 0.6)
    g.polygon("fill", -p.width * 0.2, p.height / 2, 0, p.height / 2 + fh, p.width * 0.2, p.height / 2)
    g.setColor(c[1] * 0.8, c[2] * 0.9, 1, 0.4)
    g.polygon("fill", -p.width * 0.12, p.height / 2, 0, p.height / 2 + fh * 0.7, p.width * 0.12, p.height / 2)
    g.setColor(c[1], c[2], c[3])
    g.polygon("fill", 0, -p.height / 2, p.width / 2, p.height / 3, p.width / 3, p.height / 2, -p.width / 3, p.height / 2, -p.width / 2, p.height / 3)
    g.setColor(c[1] * 1.2, c[2] * 1.1, c[3] * 1.2, 0.7)
    g.polygon("line", 0, -p.height / 2, p.width / 2, p.height / 3, p.width / 3, p.height / 2, -p.width / 3, p.height / 2, -p.width / 2, p.height / 3)
    g.setColor(0.9, 0.95, 1)
    g.circle("fill", 0, -p.height * 0.12, p.width * 0.15)
    g.setColor(c[1] * 0.5, c[2] * 0.5, c[3] * 0.8)
    g.polygon("fill", p.width / 2, p.height / 3, p.width / 2 + p.width * 0.12, p.height / 2 - p.height * 0.12, p.width / 3, p.height / 2)
    g.polygon("fill", -p.width / 2, p.height / 3, -p.width / 2 - p.width * 0.12, p.height / 2 - p.height * 0.12, -p.width / 3, p.height / 2)
    g.pop()
end

return player
