PokemonRosterProtocol = {
	OPCODE = 202,
	VERSION = 1,
	MAX_PAYLOAD = 4096,
	MAX_CHUNK_SIZE = 60000,
	MAX_SNAPSHOT_PAYLOAD = 4 * 1024 * 1024,
}

local function escapeJson(value)
	return value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\b", "\\b"):gsub("\f", "\\f"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
end

local function isArray(value)
	local count, maximum = 0, 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			return false
		end
		count = count + 1
		maximum = math.max(maximum, key)
	end
	return count == maximum
end

local function encodeJson(value)
	local valueType = type(value)
	if valueType == "nil" then
		return "null"
	elseif valueType == "boolean" or valueType == "number" then
		return tostring(value)
	elseif valueType == "string" then
		return '"' .. escapeJson(value) .. '"'
	elseif valueType ~= "table" then
		error("Unsupported JSON value type: " .. valueType)
	end

	local encoded = {}
	if isArray(value) then
		for index = 1, #value do
			encoded[index] = encodeJson(value[index])
		end
		return "[" .. table.concat(encoded, ",") .. "]"
	end

	for key, child in pairs(value) do
		encoded[#encoded + 1] = encodeJson(tostring(key)) .. ":" .. encodeJson(child)
	end
	return "{" .. table.concat(encoded, ",") .. "}"
end

local function sendEncodedPayload(player, buffer)
	if #buffer > PokemonRosterProtocol.MAX_SNAPSHOT_PAYLOAD then
		logger.error(
			"[PokemonRosterProtocol] Refused oversized snapshot for player {}: {} bytes (limit {}).",
			player:getName(),
			#buffer,
			PokemonRosterProtocol.MAX_SNAPSHOT_PAYLOAD
		)
		local errorPayload = encodeJson({
			version = PokemonRosterProtocol.VERSION,
			action = "roster.error",
			data = {
				message = "Capture Bag is too large to synchronize safely.",
			},
		})
		player:sendExtendedOpcode(PokemonRosterProtocol.OPCODE, errorPayload)
		return false
	end

	if #buffer <= PokemonRosterProtocol.MAX_CHUNK_SIZE then
		player:sendExtendedOpcode(PokemonRosterProtocol.OPCODE, buffer)
		return true
	end

	local offset = 1
	local chunkIndex = 1
	local chunkCount = math.ceil(#buffer / PokemonRosterProtocol.MAX_CHUNK_SIZE)
	while offset <= #buffer do
		local chunk = buffer:sub(offset, offset + PokemonRosterProtocol.MAX_CHUNK_SIZE - 1)
		local marker
		if chunkIndex == 1 then
			marker = "S"
		elseif chunkIndex == chunkCount then
			marker = "E"
		else
			marker = "P"
		end
		player:sendExtendedOpcode(PokemonRosterProtocol.OPCODE, marker .. chunk)
		offset = offset + PokemonRosterProtocol.MAX_CHUNK_SIZE
		chunkIndex = chunkIndex + 1
	end
	return true
end

function PokemonRosterProtocol.sendPayload(player, payload)
	return sendEncodedPayload(player, encodeJson(payload))
end

-- The client is only allowed to send this small command envelope. Keeping the
-- decoder schema-specific avoids executing or accepting arbitrary Lua data.
local function decodeClientPayload(buffer)
	local version = tonumber(buffer:match('"version"%s*:%s*(%d+)'))
	local action = buffer:match('"action"%s*:%s*"([%w%._-]+)"')
	if not version or not action then
		return nil
	end

	local dataText = buffer:match('"data"%s*:%s*(%b{})') or "{}"
	local function number(name)
		return tonumber(dataText:match('"' .. name .. '"%s*:%s*(-?%d+)'))
	end

	local openView = dataText:match('"open"%s*:%s*"([%w_-]+)"')
	if not openView and dataText:match('"open"%s*:%s*true') then
		openView = true
	end

	return {
		version = version,
		action = action,
		data = {
			revision = number("revision"),
			bagSlot = number("bagSlot"),
			teamSlot = number("teamSlot"),
			moveId = dataText:match('"moveId"%s*:%s*"([%w_%-]+)"'),
			open = openView or false,
		},
	}
end

local function memberPayload(entry)
	local species = PokemonSpecies.get(entry.speciesId)
	local experience = math.max(0, math.floor(tonumber(entry.experience) or 0))
	local level = math.max(1, math.floor(tonumber(entry.level) or 1))
	return {
		instanceId = tostring(entry.instanceId),
		bagSlot = entry.slot or false,
		speciesId = entry.speciesId,
		name = species and species.name or ("Species " .. entry.speciesId),
		lookType = species and species.runtime and species.runtime.lookType or 45,
		level = level,
		experience = experience,
		experienceLevelStart = PokemonProgression.experienceForLevel(level),
		experienceLevelNext = PokemonProgression.experienceForLevel(math.min(level + 1, PokemonCombatConfig.level.maximum)),
		gender = entry.gender,
		nature = entry.nature,
		currentHp = entry.currentHp,
		maxHp = entry.maxHp,
		state = entry.state,
	}
end

function PokemonRosterProtocol.snapshot(player, openView, message, success)
	local ownerGuid = player:getGuid()
	local bagEntries = PokemonCaptureBag.list(ownerGuid)
	local bag = {}
	local byInstance = {}
	for _, entry in ipairs(bagEntries) do
		local payload = memberPayload(entry)
		bag[#bag + 1] = payload
		byInstance[payload.instanceId] = payload
	end

	local team = {}
	local teamInstanceIds = {}
	local teamSlots = PokemonTeam.list(player)
	for slot = 1, PokemonTeam.MAX_SLOTS do
		local instanceId = teamSlots[slot]
		team[slot] = false
		if instanceId then
			local teamInstance = PokemonRepository.load(tostring(instanceId), ownerGuid)
			if teamInstance and teamInstance.locationType == "team" and teamInstance.locationSlot == slot then
				local member = memberPayload(teamInstance)
				teamInstanceIds[member.instanceId] = true
				team[slot] = {
					slot = slot,
					instanceId = member.instanceId,
					bagSlot = member.bagSlot,
					speciesId = member.speciesId,
					name = member.name,
					lookType = member.lookType,
					level = member.level,
					experience = member.experience,
					experienceLevelStart = member.experienceLevelStart,
					experienceLevelNext = member.experienceLevelNext,
					gender = member.gender,
					nature = member.nature,
					currentHp = member.currentHp,
					maxHp = member.maxHp,
					state = member.state,
				}
			end
		end
	end

	-- A Pokemon instance has exactly one authoritative location. A stale
	-- in-memory Capture Bag session must never make a team member appear twice.
	local filteredBag = {}
	for _, member in ipairs(bag) do
		if not teamInstanceIds[member.instanceId] then
			filteredBag[#filteredBag + 1] = member
		else
			PokemonCaptureBag.removeInstance(ownerGuid, member.instanceId)
			logger.warn("[PokemonRoster] Removed duplicated team instance {} from player {} Capture Bag session.", member.instanceId, player:getName())
		end
	end
	bag = filteredBag

	local active = PokemonSummon.get(player)
	if active then
		local activeMonster = Monster(active.creatureId)
		for slot = 1, PokemonTeam.MAX_SLOTS do
			local member = team[slot]
			if member and member.instanceId == tostring(active.instanceId) then
				if activeMonster then
					member.currentHp = math.max(activeMonster:getHealth(), 0)
					member.maxHp = math.max(activeMonster:getMaxHealth(), 1)
				end
				if active.instance then
					active.instance.currentHp = member.currentHp
					active.instance.maxHp = member.maxHp
				end
				break
			end
		end
	end
	return PokemonRosterProtocol.sendPayload(player, {
		version = PokemonRosterProtocol.VERSION,
		action = "roster.snapshot",
		data = {
			revision = PokemonTeam.getRevision(player),
			capacity = PokemonCaptureBag.capacity(ownerGuid),
			bag = bag,
			team = team,
			activeInstanceId = active and tostring(active.instanceId) or false,
			activeCreatureId = active and active.creatureId or false,
			moves = active and PokemonMoveCasting.snapshot(player, active) or {},
			serverTime = os.time(),
			open = openView or false,
			message = message or false,
			success = success ~= false,
		},
	})
end

function PokemonRosterProtocol.open(player, view)
	PokemonRosterProtocol.snapshot(player, view)
end

local function numberField(data, name)
	local value = tonumber(data and data[name])
	if not value or value ~= math.floor(value) then
		return nil
	end
	return value
end

function PokemonRosterProtocol.handle(player, buffer)
	if type(buffer) ~= "string" or #buffer == 0 or #buffer > PokemonRosterProtocol.MAX_PAYLOAD then
		return false
	end
	local decoded, payload = pcall(decodeClientPayload, buffer)
	if not decoded or type(payload) ~= "table" or payload.version ~= PokemonRosterProtocol.VERSION then
		PokemonRosterProtocol.snapshot(player, false, "Invalid roster protocol payload.", false)
		return false
	end

	local action = payload.action
	local data = type(payload.data) == "table" and payload.data or {}
	if action == "roster.request" then
		PokemonRosterProtocol.snapshot(player, data.open)
		return true
	end

	local clientRevision = numberField(data, "revision")
	if clientRevision ~= PokemonTeam.getRevision(player) then
		PokemonRosterProtocol.snapshot(player, data.open, "Team changed; roster was refreshed.", false)
		return false
	end

	local ok, message
	if action == "team.assign" then
		ok, message = PokemonTeam.assignFromCaptureBag(player, numberField(data, "bagSlot"), numberField(data, "teamSlot"))
	elseif action == "team.remove" then
		ok, message = PokemonTeam.remove(player, numberField(data, "teamSlot"))
	elseif action == "team.summon" then
		ok, message = PokemonSummon.releaseTeamSlot(player, numberField(data, "teamSlot"))
	elseif action == "move.cast" then
		ok, message = PokemonMoveCasting.cast(player, data.moveId)
	else
		PokemonRosterProtocol.snapshot(player, false, "Unknown roster action.", false)
		return false
	end
	PokemonRosterProtocol.snapshot(player, data.open, message, ok)
	return ok
end
