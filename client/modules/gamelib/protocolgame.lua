local opcodeCallbacks = {}
local extendedCallbacks = {}
local extendedJSONCallbacks = {}
local extendedJSONData = {}
local maxPacketSize = 65000
local maxJSONMessageSize = 4 * 1024 * 1024

local function decodeExtendedJSON(opcode, buffer)
    if #buffer > maxJSONMessageSize then
        g_logger.error(string.format(
            'Extended JSON opcode %d exceeded the %d byte limit',
            opcode,
            maxJSONMessageSize
        ))
        return nil
    end

    local ok, data = pcall(json.decode, buffer)
    if not ok then
        g_logger.error(string.format('Invalid data in extended JSON opcode %d: %s', opcode, tostring(data)))
        return nil
    end
    return data
end

function ProtocolGame:onOpcode(opcode, msg)
    for i, callback in pairs(opcodeCallbacks) do
        if i == opcode then
            callback(self, msg)
            return true
        end
    end
    return false
end

function ProtocolGame:onExtendedOpcode(opcode, buffer)
    local callback = extendedCallbacks[opcode]
    if callback then
        callback(self, opcode, buffer)
    end

    callback = extendedJSONCallbacks[opcode]
    if callback then
        local status = buffer:sub(1, 1) -- unmarked - one message, S - start, P - part, E - end
        local data = buffer:sub(2)
        local complete

        if status == 'S' then
            extendedJSONData[opcode] = data
        elseif status == 'P' or status == 'E' then
            if not extendedJSONData[opcode] then
                g_logger.error(string.format(
                    'Extended JSON opcode %d received %s without a start frame',
                    opcode,
                    status
                ))
                return
            end
            extendedJSONData[opcode] = extendedJSONData[opcode] .. data
            if status == 'E' then
                complete = extendedJSONData[opcode]
                extendedJSONData[opcode] = nil
            end
        else
            extendedJSONData[opcode] = nil
            complete = buffer
        end

        if extendedJSONData[opcode] and #extendedJSONData[opcode] > maxJSONMessageSize then
            g_logger.error(string.format(
                'Extended JSON opcode %d exceeded the %d byte assembly limit',
                opcode,
                maxJSONMessageSize
            ))
            extendedJSONData[opcode] = nil
            return
        end

        if complete then
            local jsonData = decodeExtendedJSON(opcode, complete)
            if jsonData ~= nil then
                callback(self, opcode, jsonData)
            end
        end
    end
end

function ProtocolGame.registerOpcode(opcode, callback)
    if opcodeCallbacks[opcode] then
        error('opcode ' .. opcode .. ' already registered will be overriden')
    end

    opcodeCallbacks[opcode] = callback
end

function ProtocolGame.unregisterOpcode(opcode)
    opcodeCallbacks[opcode] = nil
end

function ProtocolGame.registerExtendedOpcode(opcode, callback)
    if not callback or type(callback) ~= 'function' then
        error('Invalid callback.')
    end

    if opcode < 0 or opcode > 255 then
        error('Invalid opcode. Range: 0-255')
    end

    if extendedCallbacks[opcode] then
        error('Opcode is already taken.')
    end

    extendedCallbacks[opcode] = callback
end

function ProtocolGame.unregisterExtendedOpcode(opcode)
    if opcode < 0 or opcode > 255 then
        error('Invalid opcode. Range: 0-255')
    end

    if not extendedCallbacks[opcode] then
        error('Opcode is not registered.')
    end

    extendedCallbacks[opcode] = nil
end

function ProtocolGame.registerExtendedJSONOpcode(opcode, callback)
    if not callback or type(callback) ~= 'function' then
        error('Invalid callback.')
    end

    if opcode < 0 or opcode > 255 then
        error('Invalid opcode. Range: 0-255')
    end

    if extendedJSONCallbacks[opcode] then
        error('Opcode is already taken.')
    end

    extendedJSONCallbacks[opcode] = callback
end

function ProtocolGame.unregisterExtendedJSONOpcode(opcode)
    if opcode < 0 or opcode > 255 then
        error('Invalid opcode. Range: 0-255')
    end

    if not extendedJSONCallbacks[opcode] then
        error('Opcode is not registered.')
    end

    extendedJSONCallbacks[opcode] = nil
    extendedJSONData[opcode] = nil
end

function ProtocolGame:sendExtendedJSONOpcode(opcode, data)
    if opcode < 0 or opcode > 255 then
        error('Invalid opcode. Range: 0-255')
    end
    if type(data) ~= 'table' then
        error('Invalid data type, should be table')
    end

    local buffer = json.encode(data)
    local s = {}
    for i = 1, #buffer, maxPacketSize do
        s[#s + 1] = buffer:sub(i, i + maxPacketSize - 1)
    end
    if #s == 1 then
        self:sendExtendedOpcode(opcode, s[1])
        return
    end
    self:sendExtendedOpcode(opcode, 'S' .. s[1])
    for i = 2, #s - 1 do
        self:sendExtendedOpcode(opcode, 'P' .. s[i])
    end
    self:sendExtendedOpcode(opcode, 'E' .. s[#s])
end
