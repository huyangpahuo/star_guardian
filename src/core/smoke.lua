-- Automated smoke driver, only active with SG_SMOKE=1 (see conf.lua).
-- Walks menus, simulates real clicks through the widget hit-test layer,
-- runs a scripted gameplay segment and writes smoke_result.txt on success.
-- Milestones are appended to smoke_progress.txt so an interrupted run
-- still shows how far it got.
local smoke = {}

local progressLog = ""

local function note(msg)
    progressLog = progressLog .. msg .. "\n"
    pcall(function() love.filesystem.write("smoke_progress.txt", progressLog) end)
end

-- Synthesize a pointer press/release on a registered widget hit area.
local function pressId(ctx, id)
    local f = ctx.router:frame()
    local hit = f and f.layout[id]
    if not hit then
        note("MISSING WIDGET: " .. tostring(id) .. " (scene " .. ctx.router:currentName() .. ")")
        return nil
    end
    local x, y
    if hit.kind == "circle" then
        x, y = hit.cx, hit.cy
    else
        x, y = hit.x + hit.w / 2, hit.y + hit.h / 2
    end
    ctx.router:pointerpressed(x, y)
    ctx.router:pointerreleased(x, y)
    return id
end

function smoke.start(ctx)
    local runflow = require("src.game.runflow")

    -- SG_SMOKE=2: idle heartbeat mode, no interactions; proves the base
    -- game loop (menu draw/update) survives on its own.
    if os.getenv("SG_SMOKE") == "2" then
        local frame = 0
        return {
            tick = function()
                frame = frame + 1
                if frame % 20 == 0 then note("idle frame " .. frame .. " scene=" .. ctx.router:currentName()) end
                if frame == 300 then
                    note("idle OK")
                    pcall(function() love.filesystem.write("smoke_result.txt", "SMOKE_OK idle frames=" .. frame .. "\n") end)
                    love.event.quit()
                end
            end,
        }
    end

    local frame = 0
    local actions = ctx.input.actions
    note("smoke start")
    return {
        tick = function()
            frame = frame + 1
            if frame >= 5 and frame <= 16 then note("tick " .. frame) end
            local R = ctx.router

            -- menu overlays: ship select / settings (with slider drag) / language
            if frame == 4 then R:push("ship_select"); note("ship_select open")
            elseif frame == 7 then note("click " .. tostring(pressId(ctx, "right_arrow")))
            elseif frame == 9 then note("click " .. tostring(pressId(ctx, "left_arrow")))
            elseif frame == 11 then R:pop()
            elseif frame == 13 then R:push("settings"); note("settings open")
            elseif frame == 16 then
                local hit = R:frame().layout.music
                if hit then
                    sliderPos = {x = hit.x + hit.w * 0.5, y = hit.y + hit.h / 2}
                    R:pointerpressed(sliderPos.x, sliderPos.y)
                    R:pointermoved(sliderPos.x + 80, sliderPos.y)
                    R:pointerreleased(sliderPos.x, sliderPos.y)
                    note("slider drag, music=" .. string.format("%.2f", ctx.audio.musicVol))
                end
            elseif frame == 18 then note("click " .. tostring(pressId(ctx, "back")))
            elseif frame == 20 then R:push("language"); note("language open")
            elseif frame == 22 then note("click " .. tostring(pressId(ctx, "lang_zh_CN")))
            elseif frame == 24 then note("click " .. tostring(pressId(ctx, "back")))
            elseif frame == 26 then
                runflow.start(ctx)
                note("run started, scene=" .. R:currentName())
            elseif frame > 26 and frame < 80 then
                actions.left = (frame % 40) < 20
                actions.right = not actions.left
                actions.shoot = (frame % 10) < 6
            elseif frame == 80 then
                actions.left, actions.right, actions.shoot = false, false, false
                R:push("paused")
                note("paused open")
            elseif frame == 82 then note("click " .. tostring(pressId(ctx, "resume")))
            elseif frame == 85 then R:push("round_transition")
            elseif frame == 87 then note("click " .. tostring(pressId(ctx, "continue")))
            elseif frame == 90 then R:push("exit_prompt")
            elseif frame == 92 then note("click " .. tostring(pressId(ctx, "no")))
            elseif frame == 95 then
                ctx.session.score = ctx.session.score + 5000
                ctx.session.kills = ctx.session.kills + 30
                ctx.session.damageTaken = ctx.session.damageTaken + 40
                runflow.finish(ctx)
                note("run finished, scene=" .. R:currentName())
            elseif frame == 98 then note("click " .. tostring(pressId(ctx, "restart")))
            elseif frame == 101 then
                R:keypressed("p")
                note("paused via P, scene=" .. R:currentName())
            elseif frame == 103 then note("click " .. tostring(pressId(ctx, "exit")))
            elseif frame == 106 then
                note("menu lang=" .. ctx.i18n.lang .. " scene=" .. R:currentName())
                ctx.save.write()
                pcall(function()
                    love.filesystem.write("smoke_result.txt",
                        "SMOKE_OK frames=" .. frame
                        .. " score=" .. ctx.session.score
                        .. " scene=" .. R:currentName()
                        .. " lang=" .. ctx.i18n.lang
                        .. " bestScore=" .. tostring(ctx.save.data.stats.bestScore) .. "\n")
                end)
                note("SMOKE_OK")
                love.event.quit()
            end
        end,
    }
end

return smoke
