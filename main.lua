local bit = bit or require "bit32"
local cpu = require "lua-8080.cpu"
local bus = require "lua-8080.bus"
local ram = require "lua-8080.ram"
local ui = require "ui"
local dazzler = require "dazzler"

local cycles = 0

-- Allocate 0xFFFF bytes of randomized RAM
local wram = ram(0x10000, 0)
for address = 0x0000, 0xFFFF do
    wram[address] = love.math.random(0, 255)
end
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
--local debug_file, disassembler
--if arg[2] == "debug" or arg[3] == "debug" then
--    disassembler = require "lua-8080.disassembler"
--    disassembler:disassemble(bus)
--    debug_file = io.open("debug.log", "w")
--end

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

cpu:init(bus)
cpu.registers.pc = 0

dazzler:init(bus)

ui:init(cpu, dazzler)

function love.update(dt)
    while true do
        --if debug_file then
        --    -- Print debug output to terminal. Format inspired by superzazu's emulator,
        --    -- for easy diffing. https://github.com/superzazu/8080
        --    debug_file:write(
        --        string.format("PC: %04X, AF: %04X, BC: %04X, DE: %04X, HL: %04X, SP: %04X, CYC: %-6d (%02X %02X %02X %02X) - %s\n",
        --            cpu.registers.pc,
        --            cpu.registers.psw,
        --            cpu.registers.bc,
        --            cpu.registers.de,
        --            cpu.registers.hl,
        --            cpu.registers.sp,
        --            cycles,
        --            bus[cpu.registers.pc],
        --            bus[cpu.registers.pc+1],
        --            bus[cpu.registers.pc+2],
        --            bus[cpu.registers.pc+3],
        --            disassembler.memory[cpu.registers.pc]
        --        )
        --    )
        --end

        cycles = cycles + cpu:cycle()
        if cycles > 2000000 / 60 then
            cycles = cycles - (20000000 / 60)
            break
        end
    end
end

function love.draw()
    dazzler:draw()
    ui:draw()
end