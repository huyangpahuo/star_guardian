function love.conf(t)
    t.identity = "star_guardian"
    t.version = "11.4"
    t.window.title = "Star Guardian"
    t.window.width = 900
    t.window.height = 650
    t.window.minWidth = 640
    t.window.minHeight = 480
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.highdpi = true
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    t.modules.touch = true

    -- Smoke tests (SG_SMOKE=1) run against a throwaway save directory and
    -- open their window off-screen so they never disturb the desktop.
    if os.getenv("SG_SMOKE") == "1" then
        t.identity = "star_guardian_smoke"
        t.window.x = 8000
        t.window.y = 8000
    end
end
