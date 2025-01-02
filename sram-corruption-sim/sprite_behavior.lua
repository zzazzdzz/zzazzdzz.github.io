vba.print("R/B sprite behavioral analysis")
vba.print("TheZZAZZGlitch 2016")

log = io.open("behavior.txt", "w")
io.output(log)

function opLog(s)
    -- io.write(s .. " 0x" .. DEC_HEX(memory.getregister('a')) .. "\n")
    io.write(s .. "\n")
end
function opLogCritical(s)
    io.write(s .. "\n")
    vba.print(s)
end

function DEC_HEX(IN)
    if IN == 0 then
        return "0"
    end
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

function operationMemoryFill(a)
    local b = memory.getregister('a')
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("1 0x" .. DEC_HEX(a) .. " 0x" .. DEC_HEX(b))
    end
end

function operationSwapNibbles(a)
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("2 0x" .. DEC_HEX(a) .. " 0")
    end
end

function operationDiffEncode(a)
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("3 0x" .. DEC_HEX(a) .. " " .. memory.readbyteunsigned(0xd0aa))
    end
end

function operationNibbleReverse(a)
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("4 0x" .. DEC_HEX(a) .. " 0")
    end
end

function operationXorAddr(a)
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("5 0x" .. DEC_HEX(a) .. " 0x" .. DEC_HEX(memory.getregister('hl')-1))
    end
end

function operationCopyAddr(a, b)
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("6 0x" .. DEC_HEX(a) .. " 0x" .. DEC_HEX(b))
    end
end

function operationBitset(a)
    local b = memory.getregister('e')
    if b == 0 then
        -- ors with 0 are irrelevant
        return
    end
    if (a >= 0xa000 and a <= 0xbfff) then
        opLog("7 0x" .. DEC_HEX(a) .. " 0x" .. DEC_HEX(b))
    end
end

function operationResetLastResult()
    opLog("8 0 0")
end

highestWrite = 0x0000

function breakpoint(writeAddr)
    local writeOrigin = memory.getregister('pc')
    if writeOrigin == 0x36e3 or writeOrigin == 0x36e4 or writeOrigin == 0x16e3  or writeOrigin == 0x16e4 then
        operationMemoryFill(writeAddr)
    elseif writeOrigin == 0x266e or writeOrigin == 0x266f then
        operationBitset(writeAddr)
    elseif writeOrigin == 0x2729 or writeOrigin == 0x272a then
        operationDiffEncode(writeAddr)
    elseif writeOrigin == 0x280a or writeOrigin == 0x280b then
        operationNibbleReverse(writeAddr)
    elseif writeOrigin == 0x280f or writeOrigin == 0x2810 then
        operationXorAddr(writeAddr)
    elseif writeOrigin == 0x16d1 or writeOrigin == 0x16d2 then
        operationCopyAddr(writeAddr, memory.getregister('de')-1)
    elseif writeOrigin == 0x16fe or writeOrigin == 0x16ff then
        operationCopyAddr(writeAddr, memory.getregister('de')+1)
    elseif writeOrigin == 0x1701 or writeOrigin == 0x1702 then
        operationCopyAddr(writeAddr, memory.getregister('bc')+1)
    elseif writeOrigin == 0x1704 or writeOrigin == 0x1705 then
        operationCopyAddr(writeAddr, memory.getregister('de')+1)
    elseif writeOrigin == 0x1707 or writeOrigin == 0x1708 then
        operationCopyAddr(writeAddr, memory.getregister('bc')+1)
    elseif writeOrigin == 0x171b or writeOrigin == 0x171d then
        operationSwapNibbles(writeAddr)
    elseif writeAddr == 0x2748 then
        operationResetLastResult()
    else
        opLogCritical("unsafe SRAM write at " .. DEC_HEX(writeAddr) .. ", ip=" .. DEC_HEX(writeOrigin) .. ", a=" .. DEC_HEX(memory.getregister('a')))
    end
    if writeAddr > highestWrite then
        -- vba.print("highest written address is now " .. DEC_HEX(writeAddr))
        highestWrite = writeAddr
    end
end

vba.print("Registering SRAM hooks. May take a while.")

for i = 0xa000, 0xbfff do
    memory.registerwrite(i, breakpoint)
end
memory.registerexec(0x2748, breakpoint)

vba.print("Finished.")
opLog("0 0 0")
