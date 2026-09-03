local player = {
    types = {
        striker = {id = "striker", nameKey = "ship_striker", color = {0.3, 0.7, 1}, hp = 100, maxHp = 100, speed = 350, fireRate = 0.09, damage = 1, bulletSpeed = 760, skill = "none", skillKey = "skill_none", stats = {speed = 0.6, firepower = 0.5, hp = 0.5}},
        fortress = {id = "fortress", nameKey = "ship_fortress", color = {1, 0.5, 0.2}, hp = 150, maxHp = 150, speed = 250, fireRate = 0.28, damage = 3, bulletSpeed = 500, skill = "heavy", skillKey = "skill_heavy", stats = {speed = 0.3, firepower = 0.9, hp = 0.9}},
        phantom = {id = "phantom", nameKey = "ship_phantom", color = {0.2, 0.9, 0.6}, hp = 70, maxHp = 70, speed = 500, fireRate = 0.08, damage = 1, bulletSpeed = 860, skill = "double", skillKey = "skill_double", stats = {speed = 0.95, firepower = 0.6, hp = 0.3}},
        destroyer = {id = "destroyer", nameKey = "ship_destroyer", color = {0.9, 0.2, 0.4}, hp = 80, maxHp = 80, speed = 300, fireRate = 0.24, damage = 5, bulletSpeed = 950, skill = "penetrate", skillKey = "skill_penetrate", stats = {speed = 0.5, firepower = 1.0, hp = 0.4}},
    },
    current = "striker",
    order = {"striker", "fortress", "phantom", "destroyer"}
}
function player.getTypes() return player.types end
function player.getOrder() return player.order end
function player.getCurrent() return player.types[player.current] end
function player.select(id) if player.types[id] then player.current = id end end
function player.getCurrentId() return player.current end
function player.applyToWorld(worldPlayer, screenH) local cfg = player.getCurrent(); worldPlayer.hp = cfg.hp; worldPlayer.maxHp = cfg.maxHp; worldPlayer.speed = cfg.speed; worldPlayer.fireRate = cfg.fireRate; worldPlayer.damage = cfg.damage; worldPlayer.bulletSpeed = cfg.bulletSpeed; worldPlayer.shipType = cfg.id; worldPlayer.skill = cfg.skill; worldPlayer.color = cfg.color; worldPlayer.y = screenH - math.min(screenH * 0.12, 80) end
return player
