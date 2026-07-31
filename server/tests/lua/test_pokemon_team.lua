local passed, failed = 0, 0
local queries = {}
local instance
local bagEntries
local battleLocked = false

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

db = {
	storeQuery = function()
		return nil
	end,
	query = function(query)
		queries[#queries + 1] = query
		return true
	end,
}

Result = {}
logger = {
	warn = function() end,
	error = function() end,
}

PokemonCaptureBag = {
	LOCATION = "capture_bag",
	getBySlot = function(_, slot)
		return bagEntries[slot]
	end,
	getByInstanceId = function(_, instanceId)
		for _, entry in pairs(bagEntries) do
			if entry.instanceId == tostring(instanceId) then
				return entry
			end
		end
		return nil
	end,
	firstFreeSlot = function()
		for slot = 1, 20 do
			if not bagEntries[slot] then
				return slot, 20
			end
		end
		return nil, 20
	end,
	removeInstance = function(_, instanceId)
		for slot, entry in pairs(bagEntries) do
			if entry.instanceId == tostring(instanceId) then
				bagEntries[slot] = nil
				return entry
			end
		end
		return nil
	end,
	addInstance = function(entry)
		bagEntries[entry.locationSlot] = entry
		return true
	end,
}

PokemonRepository = {
	load = function(instanceId, ownerGuid)
		if instance.instanceId ~= tostring(instanceId) or instance.ownerGuid ~= ownerGuid then
			return nil, "Pokemon instance not found."
		end
		return instance
	end,
	moveLocation = function(instanceId, ownerGuid, expectedVersion, locationType, locationSlot)
		if instance.instanceId ~= tostring(instanceId) or instance.ownerGuid ~= ownerGuid then
			return nil, "Pokemon instance not found."
		end
		if instance.locationVersion ~= expectedVersion then
			return nil, "Pokemon location changed."
		end
		instance.locationType = locationType
		instance.locationSlot = locationSlot
		instance.locationVersion = instance.locationVersion + 1
		return instance
	end,
}

PokemonSummon = {
	get = function()
		return nil
	end,
	dismiss = function() end,
}

PokemonBattleLock = {
	reason = function()
		return battleLocked and "You cannot change Pokemon Team or Capture Bag during battle (10s)." or nil
	end,
}

local player = {
	getGuid = function()
		return 42
	end,
	getName = function()
		return "Trainer Test"
	end,
}

dofile("data-canary/lib/pokemon/team.lua")

local function reset(locationType, locationSlot)
	queries = {}
	battleLocked = false
	instance = {
		instanceId = "9007199254740993",
		ownerGuid = 42,
		locationType = locationType or "capture_bag",
		locationSlot = locationSlot or 2,
		locationVersion = 1,
	}
	bagEntries = {}
	if instance.locationType == "capture_bag" then
		bagEntries[instance.locationSlot] = instance
	end
	PokemonTeam.sessions = {}
	PokemonTeam.load(player)
end

test("assigns a Capture Bag instance to a team slot and persists it", function()
	reset()
	local ok = PokemonTeam.assignFromCaptureBag(player, 2, 4)
	equal(ok, true)
	equal(PokemonTeam.getSlot(player, 4), "9007199254740993")
	equal(instance.locationType, "team")
	equal(instance.locationSlot, 4)
	equal(bagEntries[2], nil)
	equal(#queries, 1)
	assert(queries[1]:find("pokemon_teams", 1, true))
	assert(queries[1]:find("9007199254740993", 1, true))
end)

test("same instance cannot occupy two team slots", function()
	reset()
	PokemonTeam.sessions[42].slots[1] = instance.instanceId
	local ok, reason = PokemonTeam.assignFromCaptureBag(player, 2, 4)
	equal(ok, false)
	assert(reason:find("already assigned", 1, true))
	equal(instance.locationType, "capture_bag")
	equal(#queries, 0)
end)

test("removing a team member returns it to the first free Capture Bag slot", function()
	reset("team", 4)
	PokemonTeam.sessions[42].slots[4] = instance.instanceId
	local ok = PokemonTeam.remove(player, 4)
	equal(ok, true)
	equal(PokemonTeam.list(player)[4], false)
	equal(instance.locationType, "capture_bag")
	equal(instance.locationSlot, 1)
	equal(bagEntries[1], instance)
	equal(#queries, 1)
end)

test("dirty save boundary persists the complete team once", function()
	reset("team", 6)
	PokemonTeam.sessions[42].slots[6] = instance.instanceId
	PokemonTeam.sessions[42].dirty = true
	equal(PokemonTeam.save(player, false), true)
	equal(#queries, 1)
	assert(queries[1]:find("pokemon_teams", 1, true))
	assert(queries[1]:find("9007199254740993", 1, true))
end)

test("clean team does not generate another query", function()
	equal(PokemonTeam.save(player, false), true)
	equal(#queries, 1)
end)

test("battle lock rejects Capture Bag and Team mutations without moving the instance", function()
	reset()
	battleLocked = true
	local ok, reason = PokemonTeam.assignFromCaptureBag(player, 2, 4)
	equal(ok, false)
	assert(reason:find("during battle", 1, true))
	equal(instance.locationType, "capture_bag")
	equal(#queries, 0)
end)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
