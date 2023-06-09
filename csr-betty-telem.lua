setTickRate(10)

-- 12 element array to store the TPMS sensor IDs
-- Array index starts at 1 (Lua default)
tpmsSensorIds = {
    419357713, -- TPMS Sensor 1
    419357714, -- TPMS Sensor 2
    419357715, -- TPMS Sensor 3
    419357716, -- TPMS Sensor 4
    419357717, -- TPMS Sensor 5
    419357718, -- TPMS Sensor 6
    419357719, -- TPMS Sensor 7
    419357720, -- TPMS Sensor 8
    419357721, -- TPMS Sensor 9
    419357722, -- TPMS Sensor 10
    419357723, -- TPMS Sensor 11
    419357724  -- TPMS Sensor 12
}    

function split8(val)
    return bit.band(val, 0x0F), bit.band(bit.rshift(val,4), 0x0F)
end

-- Read the TPMS data and encode pressure and temperature messages
function processTpms()
    local canChannel = 1
    local id, ext, data = rxCAN(canChannel, 100)
    local txPressureData = {0,0,0,0,0,0,0,0}
    local txTempData = {0,0,0,0,0,0,0,0}

    if id ~= nil and ext == 0 and id == 1602 then -- 4 x 12 position switch
        flPos, frPos = split8(data[1])
        rlPos, rrPos = split8(data[2])
    end

    if flPos > 0 and frPos > 0 and rlPos > 0 and rrPos > 0 then -- ensure we know all switch positions
        for k,v in ipairs({flPos, frPos, rlPos, rrPos}) do
            if id ~= nil and ext == 1 and id == tpmsSensorIds[v] then
                -- debug
                println("Processing TPMS sensor " .. tpmsSensorIds[v])
                println("Pressure: " .. data[1] .. " PSI")
                println("Temp: " .. data[3] .. " C")
                -- end debug
                txPressureData[(k * 2) - 1] = data[1]
                txTempData[k] = data[3]
            end
        end
    end
    txTpmsData(txPressureData, txTempData)
end

-- Transmit TPMS pressure and temperature data
function txTpmsData(pressure, temp)
    local canChannel = 1
    local idP = 512
    local idT = 513
    txCAN(canChannel, idP, 0, pressure)
    txCAN(canChannel, idT, 0, pressure)
end

function onTick()
    processTpms()
end