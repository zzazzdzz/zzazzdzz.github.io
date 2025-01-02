function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

function decode_u2(x)
    if x < 0x80 then
        return x
    else
        return -1 * (0x100 - x)
    end
end

function static_analysis(c, depth)
    writes = 0
    jumps = 0
    changes = 0
    halted = 0
    vbaonly = 0
    
    opcodes = {1,3,1,1,1,1,2,1,3,1,1,1,1,1,2,1,2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1,2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1,2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,3,3,1,2,1,1,1,3,1,3,3,2,1,1,1,3,0,3,1,2,1,1,1,3,0,3,0,2,1,2,1,2,0,0,1,2,1,2,1,3,0,0,0,2,1,2,1,2,1,0,1,2,1,2,1,3,1,0,0,2,1}
    opcodes[0xcb] = 2
    ip = 1
    iters = depth
    while(1) do
        if ip < 1 then
            ip = 1
        end
        if c[ip] == nil then
            --writes = 0
            break
        end
        -- bad opcodes
        -- c[ip] == 0x10XX is a corrupted stop and should crash the game, but vba seems to have an emulation error
        if c[ip] == 0xff or c[ip] == 0xc2 or c[ip] == 0xd2 or c[ip] == 0xc4 or c[ip] == 0xd4 or c[ip] == 0xcc or c[ip] == 0xcd or c[ip] == 0xdc or c[ip] == 0xc7 or c[ip] == 0xd7 or c[ip] == 0xe7 or c[ip] == 0xf7 or c[ip] == 0xef or c[ip] == 0xdf or c[ip] == 0xcf then
            -- or c[ip] == 0xc9 or c[ip] == 0xd9 or c[ip] == 0xc0 or c[ip] == 0xd0 or c[ip] == 0xd8 then
            --writes=0
            break
        end
        if c[ip] == 0x10 then
            vbaonly=1
        end
        -- 8-bit writes to address
        if c[ip] == 0x02 or c[ip] == 0x12 or c[ip] == 0x22 or c[ip] == 0x32 or c[ip] == 0x36 or c[ip] == 0x70 or c[ip] == 0x71 or c[ip] == 0x72 or c[ip] == 0x73 or c[ip] == 0x74 or c[ip] == 0x75 or c[ip] == 0x77 then
            writes = writes+1
        end
        -- changes
        if c[ip] == 0x03 or c[ip] == 0x13 or c[ip] == 0x23 or c[ip] == 0x0b or c[ip] == 0x1b or c[ip] == 0x2b or c[ip] == 0x09 or c[ip] == 0x19 or c[ip] == 0x29 or c[ip] == 0x39 or c[ip] == 0xe8 or c[ip] == 0x33 or c[ip] == 0x3b then
            changes = changes+1
        end
        if c[ip] == 0x76 then
            halted = halted+1
        end
        -- relative jumps
        jumpoccured=0
        if c[ip] == 0x30 or c[ip] == 0x20 or c[ip] == 0x18 or c[ip] == 0x38 then
            jumpoccured=1
            --vba.print('jumped from ' .. ip .. ' to ' .. (ip+decode_u2(c[ip+1])+2))
            ip = ip + decode_u2(c[ip+1]) + 2
            jumps = jumps + 1
            if ip < 1 then
                ip = 1
            end
            if c[ip] == nil then
                break
            end 
        end
        --vba.print(ip .. ' => ' .. c[ip])
        if jumpoccured == 0 then
            ip = ip + opcodes[c[ip]+1]
        end
        iters = iters - 1
        if iters == 0 then
            break
        end
    end
    color = '#ffffff'
    if writes>=30 and jumps>=10 and changes>=50 then
        color = '#ff0000'
    end
    halttext=''
    if halted>0 then
        halttext=halttext.."\nHALTED"
    end
    if vbaonly>0 and color == '#ff0000' then
        halttext=halttext.."\nVBA ONLY"
    end
    if color == '#ff0000' and halted > 0 then
        --vba.pause()
    end
    return {out="writes   : " .. writes .. "\njumps    : " .. jumps .. "\nchanges  : " .. changes .. halttext, col=color}
end

vba.print("Coin case static code analysis")
vba.print("TheZZAZZGlitch 2015")
while(1) do
	local c,r
    mem = {}
    
    test = joypad.get(1)
    for i=1,0x80 do
        mem[i] = memory.readbyteunsigned(0xcc1f+i);
    end
    if test.select then
        anal = static_analysis(mem, 20000)
        gui.text(2, 2, anal.out, '#ffff00')
        --vba.pause()
    else
        anal = static_analysis(mem, 1000)
        gui.text(2, 2, anal.out, anal.col)
    end
	vba.frameadvance()
end