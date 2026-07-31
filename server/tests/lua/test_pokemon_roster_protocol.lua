local passed, failed = 0, 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		io.stderr:write(string.format("FAIL %s: %s\n", name, err))
	end
end

local function equal(actual, expected)
	assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

local loggedErrors = 0
logger = {
	error = function()
		loggedErrors = loggedErrors + 1
	end,
}

dofile("data-canary/lib/pokemon/roster_protocol.lua")

local packets = {}
local player = {
	getName = function()
		return "Roster Transport Test"
	end,
	sendExtendedOpcode = function(_, opcode, buffer)
		packets[#packets + 1] = {
			opcode = opcode,
			buffer = buffer,
		}
	end,
}

local function reset()
	packets = {}
	loggedErrors = 0
end

test("small payload uses one unframed packet", function()
	reset()
	local ok = PokemonRosterProtocol.sendPayload(player, {
		version = 1,
		action = "roster.snapshot",
		data = { bag = {} },
	})
	equal(ok, true)
	equal(#packets, 1)
	equal(packets[1].opcode, PokemonRosterProtocol.OPCODE)
	equal(packets[1].buffer:sub(1, 1), "{")
	assert(#packets[1].buffer <= PokemonRosterProtocol.MAX_CHUNK_SIZE)
end)

test("large payload is framed and reconstructs losslessly", function()
	reset()
	local blob = string.rep("x", PokemonRosterProtocol.MAX_CHUNK_SIZE * 2 + 123)
	local ok = PokemonRosterProtocol.sendPayload(player, {
		version = 1,
		action = "roster.snapshot",
		data = { blob = blob },
	})
	equal(ok, true)
	equal(#packets, 3)
	equal(packets[1].buffer:sub(1, 1), "S")
	equal(packets[2].buffer:sub(1, 1), "P")
	equal(packets[3].buffer:sub(1, 1), "E")

	local reconstructed = {}
	for index, packet in ipairs(packets) do
		equal(packet.opcode, PokemonRosterProtocol.OPCODE)
		assert(#packet.buffer <= PokemonRosterProtocol.MAX_CHUNK_SIZE + 1)
		reconstructed[index] = packet.buffer:sub(2)
	end
	local jsonBuffer = table.concat(reconstructed)
	assert(jsonBuffer:find(blob, 1, true), "reconstructed payload lost data")
end)

test("structural Capture Bag limit fits the bounded fragmented transport", function()
	reset()
	local bag = {}
	for slot = 1, 2000 do
		bag[slot] = {
			instanceId = tostring(9000000000000000 + slot),
			bagSlot = slot,
			speciesId = 151,
			name = "Pokemon Species 151",
			lookType = 3151,
			level = 100,
			gender = "genderless",
			nature = "serious",
			currentHp = 99999,
			maxHp = 99999,
			state = "ready",
		}
	end
	local ok = PokemonRosterProtocol.sendPayload(player, {
		version = 1,
		action = "roster.snapshot",
		data = {
			revision = 1,
			capacity = 2000,
			bag = bag,
			team = {},
			activeInstanceId = false,
			activeCreatureId = false,
			open = "bag",
			message = false,
			success = true,
		},
	})
	equal(ok, true)
	assert(#packets > 1, "the 2000-slot fixture should exercise fragmentation")
	for _, packet in ipairs(packets) do
		assert(#packet.buffer <= PokemonRosterProtocol.MAX_CHUNK_SIZE + 1)
	end
end)

test("oversized payload is refused with a compact error", function()
	reset()
	local ok = PokemonRosterProtocol.sendPayload(player, {
		version = 1,
		action = "roster.snapshot",
		data = {
			blob = string.rep("x", PokemonRosterProtocol.MAX_SNAPSHOT_PAYLOAD + 1),
		},
	})
	equal(ok, false)
	equal(loggedErrors, 1)
	equal(#packets, 1)
	equal(packets[1].buffer:sub(1, 1), "{")
	assert(packets[1].buffer:find('"action":"roster.error"', 1, true))
	assert(#packets[1].buffer <= PokemonRosterProtocol.MAX_CHUNK_SIZE)
end)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
