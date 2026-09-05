-- Persistent profile: settings, lifetime stats and unlocked achievements.
-- Stored as a human-readable Lua chunk, tolerant of missing fields from
-- older save files (unknown/missing keys fall back to defaults).
local utils = require("src.core.utils")

local save = {filename = "savegame.lua", data = nil}

local defaults = {
    lang = "en",
    ship = "striker",
    highscore = 0,
    fullscreen = false,
    audio = {master = 1, sfx = 1, music = 0.4},
    stats = {runs = 0, bestScore = 0, totalScore = 0, kills = 0, deaths = 0, damageTaken = 0},
    achievements = {},
}

local function serialize(v)
    local t = type(v)
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" then return "nil" end
    local out = {"{"}
    for k, val in pairs(v) do
        local key = type(k) == "string" and k:match("^[%a_][%w_]*$") and (k .. " = ")
            or ("[" .. serialize(k) .. "] = ")
        table.insert(out, "  " .. key .. serialize(val) .. ",")
    end
    table.insert(out, "}")
    return table.concat(out, "\n")
end

-- Load the save file, merging it over defaults. Never throws: a corrupt
-- file simply falls back to defaults.
function save.init()
    save.data = utils.deepCopy(defaults)
    if love.filesystem.getInfo(save.filename) then
        local chunk = love.filesystem.load(save.filename)
        if chunk then
            local ok, loaded = pcall(chunk)
            if ok and type(loaded) == "table" then
                utils.deepMerge(save.data, loaded)
            end
        end
    end
    return save.data
end

function save.set(key, value)
    save.data[key] = value
    return save.write()
end

function save.write()
    return love.filesystem.write(save.filename, "return " .. serialize(save.data) .. "\n")
end

-- Fold one finished run into the lifetime stats and write to disk.
function save.recordRun(score, kills, damageTaken)
    local s = save.data.stats
    s.runs = s.runs + 1
    s.totalScore = s.totalScore + score
    s.bestScore = math.max(s.bestScore, score)
    s.kills = s.kills + kills
    s.damageTaken = s.damageTaken + damageTaken
    if score > save.data.highscore then save.data.highscore = score end
    save.write()
end

return save
