local passed, failed = 0, 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write(string.format('FAIL %s: %s\n', name, err))
    end
end

local function equal(actual, expected)
    assert(actual == expected, string.format('expected %s, got %s', tostring(expected), tostring(actual)))
end

json = dofile('modules/corelib/json.lua')
local loggedErrors = 0
g_logger = {
    error = function()
        loggedErrors = loggedErrors + 1
    end,
}
ProtocolGame = {}
dofile('modules/gamelib/protocolgame.lua')

local packets = {}
local protocol = setmetatable({
    sendExtendedOpcode = function(_, opcode, buffer)
        packets[#packets + 1] = {
            opcode = opcode,
            buffer = buffer,
        }
    end,
}, { __index = ProtocolGame })

local received
local function register()
    ProtocolGame.registerExtendedJSONOpcode(202, function(_, opcode, payload)
        equal(opcode, 202)
        received = payload
    end)
end

local function reset()
    packets = {}
    received = nil
    loggedErrors = 0
end

test('fragmented JSON is reconstructed before callback', function()
    reset()
    register()
    local blob = string.rep('x', 130123)
    protocol:sendExtendedJSONOpcode(202, {
        version = 1,
        action = 'roster.snapshot',
        data = { blob = blob },
    })
    equal(#packets, 3)
    equal(packets[1].buffer:sub(1, 1), 'S')
    equal(packets[2].buffer:sub(1, 1), 'P')
    equal(packets[3].buffer:sub(1, 1), 'E')
    for _, packet in ipairs(packets) do
        protocol:onExtendedOpcode(packet.opcode, packet.buffer)
    end
    equal(received.action, 'roster.snapshot')
    equal(received.data.blob, blob)
    ProtocolGame.unregisterExtendedJSONOpcode(202)
end)

test('part without start is rejected', function()
    reset()
    register()
    protocol:onExtendedOpcode(202, 'P{"version":1}')
    equal(received, nil)
    equal(loggedErrors, 1)
    ProtocolGame.unregisterExtendedJSONOpcode(202)
end)

test('unregister clears an incomplete assembly', function()
    reset()
    register()
    protocol:onExtendedOpcode(202, 'S{"version":1,')
    ProtocolGame.unregisterExtendedJSONOpcode(202)
    register()
    protocol:onExtendedOpcode(202, 'E"action":"roster.snapshot"}')
    equal(received, nil)
    equal(loggedErrors, 1)
    ProtocolGame.unregisterExtendedJSONOpcode(202)
end)

print(string.format('%d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)

