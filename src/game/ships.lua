-- Ship catalog: pure data plus selection state. No Love2D calls here, so
-- ship definitions can be inspected or tested without the engine.
local ships = {
    current = "striker",
    order = {"striker", "fortress", "phantom", "destroyer"},
    types = {
        striker = {
            id = "striker", nameKey = "ship_striker", color = {0.3, 0.7, 1},
            hp = 100, maxHp = 100, speed = 350, fireRate = 0.09, damage = 1,
            bulletSpeed = 760, skill = "none", skillKey = "skill_none",
            stats = {speed = 0.6, firepower = 0.5, hp = 0.5},
        },
        fortress = {
            id = "fortress", nameKey = "ship_fortress", color = {1, 0.5, 0.2},
            hp = 150, maxHp = 150, speed = 250, fireRate = 0.28, damage = 3,
            bulletSpeed = 500, skill = "heavy", skillKey = "skill_heavy",
            stats = {speed = 0.3, firepower = 0.9, hp = 0.9},
        },
        phantom = {
            id = "phantom", nameKey = "ship_phantom", color = {0.2, 0.9, 0.6},
            hp = 70, maxHp = 70, speed = 500, fireRate = 0.08, damage = 1,
            bulletSpeed = 860, skill = "double", skillKey = "skill_double",
            stats = {speed = 0.95, firepower = 0.6, hp = 0.3},
        },
        destroyer = {
            id = "destroyer", nameKey = "ship_destroyer", color = {0.9, 0.2, 0.4},
            hp = 80, maxHp = 80, speed = 300, fireRate = 0.24, damage = 5,
            bulletSpeed = 950, skill = "penetrate", skillKey = "skill_penetrate",
            stats = {speed = 0.5, firepower = 1.0, hp = 0.4},
        },
    },
}

function ships.getTypes() return ships.types end
function ships.getOrder() return ships.order end
function ships.getCurrent() return ships.types[ships.current] end
function ships.getCurrentId() return ships.current end

function ships.select(id)
    if ships.types[id] then ships.current = id end
end

function ships.indexOf(id)
    for i, name in ipairs(ships.order) do
        if name == id then return i end
    end
    return 1
end

function ships.at(index)
    return ships.order[((index - 1) % #ships.order) + 1]
end

return ships
