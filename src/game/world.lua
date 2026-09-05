-- World orchestrator: owns all entity state, spawns, collisions and
-- difficulty scaling. update() returns an event list so the playing scene
-- can react (audio, score, achievements) without the simulation knowing
-- about scenes.
local utils = require("src.core.utils")
local stars = require("src.game.entities.stars")
local particles = require("src.game.entities.particles")
local bullets = require("src.game.entities.bullets")
local enemies = require("src.game.entities.enemies")
local powerups = require("src.game.entities.powerups")
local shipEntity = require("src.game.entities.player")
local rounds = require("src.game.rounds")

local world = {
    starsList = {},
    bullets = {}, enemies = {}, particles = {}, powerups = {},
    player = nil,
    shootTimer = 0,
    spawnTimer = 1,
    baseSize = 600,
    width = 900, height = 650,
}

function world.init(w, h)
    world.width, world.height = w, h
    world.baseSize = math.min(w, h)
    stars.init(world.starsList, w, h)
    world.reset(w, h)
end

function world.reset(w, h)
    w = w or world.width
    h = h or world.height
    world.width, world.height = w, h
    world.baseSize = math.min(w, h)
    world.player = shipEntity.create(w, h)
    world.bullets = {}
    world.enemies = {}
    world.particles = {}
    world.powerups = {}
    world.shootTimer = 0
    world.spawnTimer = 1
end

-- Equip a ship catalog config onto the live player entity.
function world.applyShip(cfg, h)
    shipEntity.applyConfig(world.player, cfg, h or world.height)
end

function world.onResize(w, h)
    local ow, oh = world.width, world.height
    world.width, world.height = w, h
    world.baseSize = math.min(w, h)
    -- Keep the existing starfield and rescale it proportionally instead of
    -- re-rolling: re-rolling on every resize event made the sky "jump"
    -- during interactive window resizing.
    if ow and oh and ow > 0 and oh > 0 then
        local sx, sy = w / ow, h / oh
        for _, s in ipairs(world.starsList) do
            s.x = s.x * sx
            s.y = s.y * sy
        end
    end
    local p = world.player
    if p then
        p.y = h - math.min(h * 0.12, 80)
        p.x = utils.clamp(p.x, p.width / 2, w - p.width / 2)
    end
end

-- Stars/particles keep moving on overlay screens (round transition, ...).
function world.updateAmbient(dt)
    stars.update(world.starsList, dt, world.width, world.height)
    particles.update(world.particles, dt)
end

-- session: read for score-driven difficulty and the active round config.
-- actions: {left, right, shoot} from the input module.
-- Returns a list of events, e.g. {type="kill", score=25} / {type="died"}.
function world.update(dt, session, actions)
    local w, h = world.width, world.height
    local p = world.player
    local events = {}
    local died = false

    stars.update(world.starsList, dt, w, h)
    shipEntity.update(p, dt, actions, w)

    -- player fire
    world.shootTimer = world.shootTimer - dt
    if actions.shoot and world.shootTimer <= 0 then
        bullets.spawn(world.bullets, p)
        world.shootTimer = math.max(0.04, p.fireRate)
        events[#events + 1] = {type = "shoot"}
    end
    bullets.update(world.bullets, dt, p.bulletSpeed, w)

    -- spawning: round config plus score-driven difficulty
    world.spawnTimer = world.spawnTimer - dt
    if world.spawnTimer <= 0 then
        local difficulty = 1 + session.score / 1000
        enemies.spawn(world.enemies, rounds.getEnemyType(session.roundNum), w, world.baseSize, difficulty, rounds.getSpeedMult(session.roundNum))
        world.spawnTimer = math.max(0.25, rounds.getSpawnRate(session.roundNum) / difficulty)
    end

    -- enemy motion; ramming the player costs 20 HP and grants brief i-frames
    enemies.update(world.enemies, dt, w)
    for i = #world.enemies, 1, -1 do
        local e = world.enemies[i]
        if e.y > h + 50 then
            table.remove(world.enemies, i)
        elseif p.invincible <= 0 and utils.checkCollision(e, p) then
            p.hp = p.hp - 20
            p.invincible = 1.5
            particles.burst(world.particles, p.x, p.y - 10, {1, 0.5, 0}, 30)
            table.remove(world.enemies, i)
            events[#events + 1] = {type = "player_hit", damage = 20}
            if p.hp <= 0 then died = true end
        end
    end
    if died then events[#events + 1] = {type = "died"} end

    -- bullets vs enemies
    for i = #world.bullets, 1, -1 do
        local b = world.bullets[i]
        local consumed = false
        for j = #world.enemies, 1, -1 do
            local e = world.enemies[j]
            if utils.checkCollision(b, e) then
                e.hp = e.hp - b.damage
                particles.burst(world.particles, b.x, b.y, {1, 1, 0.5}, 8)
                events[#events + 1] = {type = "hit"}
                if e.hp <= 0 then
                    particles.burst(world.particles, e.x, e.y, e.color, 25)
                    events[#events + 1] = {type = "kill", score = e.score}
                    if math.random() < 0.08 then
                        powerups.spawn(world.powerups, e.x, e.y, world.baseSize)
                    end
                    table.remove(world.enemies, j)
                end
                if b.penetrate > 0 then
                    b.penetrate = b.penetrate - 1
                else
                    consumed = true
                end
                break
            end
        end
        if consumed then table.remove(world.bullets, i) end
    end

    powerups.update(world.powerups, dt, h, p, function(kind)
        events[#events + 1] = {type = "powerup", kind = kind}
    end)

    particles.update(world.particles, dt)
    return events
end

-- opts.player = false skips the ship (game over: it just exploded).
function world.draw(opts)
    opts = opts or {}
    stars.draw(world.starsList)
    powerups.draw(world.powerups)
    enemies.draw(world.enemies)
    bullets.draw(world.bullets)
    if opts.player ~= false then shipEntity.draw(world.player) end
    particles.draw(world.particles)
end

function world.explode(x, y, color, count)
    particles.burst(world.particles, x, y, color, count)
end

return world
