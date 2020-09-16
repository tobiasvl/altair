function love.conf(t)
    -- Debug mode
    t.console = false

    t.identity = "ALTAÏR"
    t.window.title = "ALTAÏR"
    t.window.resizable = true
    t.window.height = 650

    t.version = "11.3"

    -- Disable stuff we don't use
    t.accelerometerjoystick = false
    t.modules.joystick = false
    t.modules.data = false
    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end