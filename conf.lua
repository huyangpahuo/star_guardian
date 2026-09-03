function love.conf(t)
    t.identity = "star_guardian"
    t.version = "11.4"
    t.window.title = "Star Guardian"
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.width = 900
    t.window.height = 650
    t.window.resizable = false
    t.window.highdpi = true
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    t.modules.touch = true
end
