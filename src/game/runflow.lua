-- Run lifecycle shared by the menu (start/restart) and death handling.
-- Keeps scene code free of save/stats/session wiring.
local runflow = {}

function runflow.start(ctx)
    ctx.session.reset(ctx.save.data.highscore)
    ctx.world.reset(ctx.w, ctx.h)
    ctx.world.applyShip(ctx.ships.getCurrent(), ctx.h)
    ctx.achievements.resetGameData()
    ctx.router:gotoScene("playing")
end

-- Called once when the player dies: folds the run into lifetime stats,
-- saves, and switches to the game over screen.
function runflow.finish(ctx)
    local session = ctx.session
    session.runActive = false
    if session.score > session.highscore then session.highscore = session.score end
    ctx.audio.play("gameover")
    ctx.world.explode(ctx.world.player.x, ctx.world.player.y, {1, 0.3, 0.1}, 60)
    ctx.save.recordRun(session.score, session.kills, session.damageTaken)
    ctx.router:gotoScene("gameover")
end

return runflow
