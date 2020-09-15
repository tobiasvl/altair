local bit = bit or require "bit32"
local cpu = require "lua-8080.cpu"
local bus = require "lua-8080.bus"
local ram = require "lua-8080.ram"
local lg = love.graphics

local cycles = 0

-- Allocate 0xFFFF bytes of RAM
local wram = ram(0x10000, 0)
bus:connect(0, wram)

---- Load test "ROM" into RAM
--local file = io.open(arg[1], "r")
--local rom = {}
--local address = 0
--repeat
--    local b = file:read(1)
--    if b then
--        bus[0x100 + address] = b:byte()
--    end
--    address = address + 1
--until not b
--file:close()
--
local debug_file, disassembler
if arg[2] == "debug" or arg[3] == "debug" then
    disassembler = require "lua-8080.disassembler"
    disassembler:disassemble(bus)
    debug_file = io.open("debug.log", "w")
end

-- inject Dazzler test program
bus[0x0000] = 0x3E;
bus[0x0001] = 0x80;
bus[0x0002] = 0xD3;
bus[0x0003] = 0x0E;
bus[0x0004] = 0xDB;
bus[0x0005] = 0xFF;
bus[0x0006] = 0xD3;
bus[0x0007] = 0x0F;
bus[0x0008] = 0xC3;
bus[0x0009] = 0x00;
bus[0x000A] = 0x00;

for address = 0x000B, 0xFFFF do
    bus[address] = math.random(0, 255)
end

cpu:init(bus)
cpu.registers.pc = 0

local dazzler = {
    on = false,
    vram = 0,
    resolution_x4 = false,
    memory_2k = false,
    color = false,
    high_intensity = false,
    blue = false,
    green = false,
    red = false
}

local function dazzler_address(address)
    dazzler.vram = bit.lshift(address, 9)
    dazzler.on = bit.band(address, 0x80) == 0x80
end

function dazzler_format(format)
    dazzler.resolution_x4 = bit.band(format, 0x40) == 0x40
    dazzler.memory_2k = bit.band(format, 0x20) == 0x20
    dazzler.color = bit.band(format, 0x10) == 0x10
    dazzler.high_intensity = bit.band(format, 0x08) == 0x08
    dazzler.blue = bit.band(format, 0x04) == 0x04
    dazzler.green = bit.band(format, 0x02) == 0x02
    dazzler.red = bit.band(format, 0x01) == 0x01
end

function sense()
    return math.random(0, 255)
end

cpu.ports.internal.output[0x0E] = dazzler_address
cpu.ports.internal.output[0x0F] = dazzler_format
--cpu.ports.internal.input[0x0F] = dazzler_format
cpu.ports.internal.input[0xFF] = sense

function love.update(dt)
    while true do
        if debug_file then
            -- Print debug output to terminal. Format inspired by superzazu's emulator,
            -- for easy diffing. https://github.com/superzazu/8080
            debug_file:write(
                string.format("PC: %04X, AF: %04X, BC: %04X, DE: %04X, HL: %04X, SP: %04X, CYC: %-6d (%02X %02X %02X %02X) - %s\n",
                    cpu.registers.pc,
                    cpu.registers.psw,
                    cpu.registers.bc,
                    cpu.registers.de,
                    cpu.registers.hl,
                    cpu.registers.sp,
                    cycles,
                    bus[cpu.registers.pc],
                    bus[cpu.registers.pc+1],
                    bus[cpu.registers.pc+2],
                    bus[cpu.registers.pc+3],
                    disassembler.memory[cpu.registers.pc]
                )
            )
        end
    
        cycles = cycles + cpu:cycle()
        if cycles > 2000000 then
            cycles = cycles - 20000000
            break
        end
    end
end

function love.draw()
    if dazzler_on then
        for y = 0, 31 do
            for x = 0, 7 do
                local byte = bus[vram + (y * 8) + x]
                for xx = 0, 7 do
                    local pixel = bit.band(byte, 0x80)
                    byte = bit.lshift(byte, 1)
                    if pixel ~= 0 then
                        lg.rectangle("fill", (x * 64) + (xx * 8), y * 8, 8, 8)
                    end
                end
            end
        end
    end
end
