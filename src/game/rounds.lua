-- Round (wave) configuration. `enemies` is an ordered list of
-- {type, weight} pairs so random picking is deterministic regardless of
-- Lua's unordered pairs() iteration.
local rounds = {
    configs = {
        {nameKey = "round1_name", descKey = "round1_desc", targetScore = 200,
         enemies = {{"scout", 1.0}}, spawnRate = 1.2, speedMult = 1.0},
        {nameKey = "round2_name", descKey = "round2_desc", targetScore = 500,
         enemies = {{"scout", 0.5}, {"fighter", 0.5}}, spawnRate = 1.0, speedMult = 1.1},
        {nameKey = "round3_name", descKey = "round3_desc", targetScore = 1000,
         enemies = {{"scout", 0.3}, {"fighter", 0.4}, {"tank", 0.3}}, spawnRate = 0.85, speedMult = 1.2},
        {nameKey = "round4_name", descKey = "round4_desc", targetScore = 1800,
         enemies = {{"scout", 0.2}, {"fighter", 0.3}, {"tank", 0.2}, {"speeder", 0.3}}, spawnRate = 0.7, speedMult = 1.3},
        {nameKey = "round5_name", descKey = "round5_desc", targetScore = 3000,
         enemies = {{"scout", 0.2}, {"fighter", 0.25}, {"tank", 0.25}, {"speeder", 0.3}}, spawnRate = 0.6, speedMult = 1.4},
        {nameKey = "round6_name", descKey = "round6_desc", targetScore = math.huge,
         enemies = {{"scout", 0.2}, {"fighter", 0.25}, {"tank", 0.25}, {"speeder", 0.3}}, spawnRate = 0.5, speedMult = 1.5},
    },
}

function rounds.getConfig(roundNum)
    return rounds.configs[math.min(roundNum, #rounds.configs)]
end

function rounds.checkAdvance(score, roundNum)
    return score >= rounds.getConfig(roundNum).targetScore
end

function rounds.getEnemyType(roundNum)
    local cfg = rounds.getConfig(roundNum)
    local r, cum = math.random(), 0
    for _, pair in ipairs(cfg.enemies) do
        cum = cum + pair[2]
        if r <= cum then return pair[1] end
    end
    return cfg.enemies[1][1]
end

function rounds.getSpawnRate(roundNum) return rounds.getConfig(roundNum).spawnRate end
function rounds.getSpeedMult(roundNum) return rounds.getConfig(roundNum).speedMult end

return rounds
