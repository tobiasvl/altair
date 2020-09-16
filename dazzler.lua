local lg = love.graphics

local dazzler = {
    on = false,
    vram = 0,
    resolution_x4 = false,
    memory_2k = false,
    color = false,
    high_intensity = false,
    blue = false,
    green = false,
    red = false,
    canvas = lg.newCanvas(8 * 64, 8 * 64)
}

function dazzler:init(bus)
    self.bus = bus
end

function dazzler:draw()
    lg.setCanvas(self.canvas)
    lg.clear() -- ??
    if self.on then
        if self.resolution_x4 then
            local red = self.red and 1 or 0
            local green = self.green and 1 or 0
            local blue = self.blue and 1 or 0
            local intensity = self.high_intensity and 1 or 0.5
            lg.setColor(red, green, blue, intensity)
            local pixel_size = self.memory_2k and 8 or 16
            for quadrant = 0, self.memory_2k and 3 or 0 do
                local base_address = self.vram + (quadrant * 512)
                for y = 0, 63, 2 do
                    for x = 0, 63, 4 do
                        local byte = self.bus[base_address + (y * 16) + math.floor(x / 2)]
                        for xx = 0, 7 do
                            local pixel = bit.band(byte, 0x01)
                            byte = bit.rshift(byte, 1)
                            local x_pos = ((x + (quadrant % 2)) * 32) + (xx * pixel_size)
                            local y_pos = y * pixel_size * (math.floor(quadrant / 2) * 32)
                            if pixel ~= 0 then
                                lg.rectangle("fill", x_pos, y_pos, pixel_size, pixel_size)
                            end
                        end
                    end
                end
            end
        else
            local pixel_size = self.memory_2k and 4 or 8
            for quadrant = 0, self.memory_2k and 3 or 0 do
                local base_address = self.vram + (quadrant * 512)
                for y = 0, 63 do
                    for x = 0, 63, 2 do
                        local byte = self.bus[base_address + (y * 16) + math.floor(x / 2)]
                        for nybble = 0, 1 do
                            byte = bit.lshift(byte, 4 * nybble)
                            local red = bit.band(bit.rshift(byte, 7), 1)
                            local green = bit.band(bit.rshift(byte, 6), 1)
                            local blue = bit.band(bit.rshift(byte, 5), 1)
                            local intensity = math.max(bit.band(bit.rshift(byte, 4), 1), 0.5)
                            lg.setColor(red, green, blue, intensity)
                            local x_pos = (x + (nybble * 1) + (quadrant % 2) * 64) * pixel_size
                            local y_pos = (y + (math.floor(quadrant / 2) * 64)) * pixel_size
                            lg.rectangle("fill", x_pos, y_pos, pixel_size, pixel_size)
                        end
                    end
                end
            end
        end
    end

    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()
end

return dazzler