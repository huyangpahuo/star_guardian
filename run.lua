local run = {
    active = false,
}

function run.start(game)
    run.active = true
    game.score = 0
end

function run.stop()
    run.active = false
end

return run
