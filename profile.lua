local profile = {
    data = {
        lang = "en",
        fullscreen = false,
        audio = {master = 1, sfx = 1, music = 0.4},
        stats = {runs = 0, bestScore = 0, totalScore = 0, kills = 0, deaths = 0, damageTaken = 0},
    }
}

function profile.merge(saved)
    if type(saved) ~= "table" then return end
    for k, v in pairs(saved) do
        profile.data[k] = v
    end
end

function profile.get()
    return profile.data
end

return profile
