-- Per-run progression state (score / level / round). Lifetime totals live
-- in the save module; this table is reset at the start of every run.
local session = {
    score = 0,
    level = 1,
    roundNum = 1,
    highscore = 0,
    kills = 0,
    damageTaken = 0,
    runActive = false,
}

function session.reset(highscore)
    session.score = 0
    session.level = 1
    session.roundNum = 1
    session.kills = 0
    session.damageTaken = 0
    session.highscore = highscore or session.highscore
    session.runActive = true
end

-- Score is the single driver of level progression (500 points per level).
function session.addScore(n)
    session.score = session.score + n
    session.level = math.floor(session.score / 500) + 1
end

return session
