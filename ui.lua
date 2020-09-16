local lg = love.graphics
local bit = bit or require "bit32"
local imgui = require "imgui"

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y, true)
end

function love.mousepressed(_, _, button)
    imgui.MousePressed(button)
end

function love.mousereleased(_, _, button)
    imgui.MouseReleased(button)
end

function love.wheelmoved(_, y)
    imgui.WheelMoved(y)
end

function love.keypressed(key, scancode)
    imgui.KeyPressed(key)
end

love.keyreleased = imgui.KeyReleased
love.textinput = imgui.TextInput
love.quit = imgui.ShutDown

local dot = lg.newCanvas(20, 10)
local filled_dot = lg.newCanvas(20, 10)

local ui = {}

function ui:init(cpu, dazzler)
    self.cpu = cpu
    self.dazzler = dazzler

    lg.setCanvas(dot)
    lg.setColor(1, 0, 0, .5)
    lg.circle("fill", 7, 5, 5)
    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()

    lg.setCanvas(filled_dot)
    lg.setColor(1, 0, 0, 1)
    lg.circle("fill", 7, 5, 5)
    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()

    self.cpu.ports.internal.output[0x0E] = function(address)
        self.dazzler.vram = bit.band(bit.lshift(address, 9), 0xFFFF)
        self.dazzler.on = bit.band(address, 0x80) == 0x80
    end

    self.cpu.ports.internal.output[0x0F] = function(format)
        self.dazzler.resolution_x4 = bit.band(format, 0x40) == 0x40
        self.dazzler.memory_2k = bit.band(format, 0x20) == 0x20
        self.dazzler.color = bit.band(format, 0x10) == 0x10
        self.dazzler.high_intensity = bit.band(format, 0x08) == 0x08
        self.dazzler.blue = bit.band(format, 0x04) == 0x04
        self.dazzler.green = bit.band(format, 0x02) == 0x02
        self.dazzler.red = bit.band(format, 0x01) == 0x01
    end

    self.sense_switches = {
    [0]=false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    }

    self.cpu.ports.internal.input[0xFF] = function()
        local byte = 0
        for i = 0, 7 do
            byte = bit.bor(byte, bit.lshift(self.sense_switches[i] and 1 or 0, i))
        end
        return byte
    end
end

function ui:draw()
    imgui.NewFrame()

    imgui.SetNextWindowPos(0, 0)--, "ImGuiCond_FirstUseEver")
    imgui.SetNextWindowSize(66 * 8, 69 * 8)--, "ImGuiCond_FirstUseEver")
    imgui.Begin("Dazzler", true, {})
    imgui.Image(self.dazzler.canvas, self.dazzler.canvas:getWidth(), self.dazzler.canvas:getHeight())
    imgui.End()

    imgui.SetNextWindowPos(0, lg.getHeight() - 100)--, "ImGuiCond_FirstUseEver")
    imgui.SetNextWindowSize(66 * 8, 69 * 8)--, "ImGuiCond_FirstUseEver")
    imgui.Begin("Front panel", true, { })

    for i = 15, 0, -1 do
        if bit.band(bit.rshift(self.cpu.registers.pc, i), 1) == 1 then
            imgui.Image(filled_dot, 20, 10)
        else
            imgui.Image(dot, 20, 10)
        end
        if i ~= 0 then imgui.SameLine() end
    end

    for i = 7, 0, -1 do
        self.sense_switches[i] = imgui.Checkbox("##sense" .. i, self.sense_switches[i])
        imgui.SameLine()
    end

    for i = 7, 0, -1 do
        imgui.Checkbox("")
        imgui.SameLine()
    end

    imgui.End()

    imgui.Render()
end

return ui