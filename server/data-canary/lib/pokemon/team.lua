PokemonTeam = {
	MAX_SLOTS = 6,
	sessions = {},
}

local function guidOf(playerOrGuid)
	if type(playerOrGuid) == "number" then
		return playerOrGuid
	end
	return playerOrGuid:getGuid()
end

local function emptySlots()
	return { false, false, false, false, false, false }
end

local function validSlot(slot)
	return type(slot) == "number" and slot == math.floor(slot) and slot >= 1 and slot <= PokemonTeam.MAX_SLOTS
end

function PokemonTeam.load(player)
	local ownerGuid = player:getGuid()
	local slots = emptySlots()
	local resultId = db.storeQuery(string.format([[
		SELECT
			COALESCE(`slot_1`, 0) AS `slot_1`,
			COALESCE(`slot_2`, 0) AS `slot_2`,
			COALESCE(`slot_3`, 0) AS `slot_3`,
			COALESCE(`slot_4`, 0) AS `slot_4`,
			COALESCE(`slot_5`, 0) AS `slot_5`,
			COALESCE(`slot_6`, 0) AS `slot_6`
		FROM `pokemon_teams`
		WHERE `player_id` = %d
		LIMIT 1;
	]], ownerGuid))

	if resultId then
		for slot = 1, PokemonTeam.MAX_SLOTS do
			local instanceId = Result.getString(resultId, "slot_" .. slot)
			if instanceId and instanceId ~= "0" then
				local instance = PokemonRepository.load(tostring(instanceId), ownerGuid)
				if instance and instance.locationType == "team" and instance.locationSlot == slot then
					slots[slot] = tostring(instanceId)
				else
					logger.warn("[PokemonTeam] Removed instance {} with invalid location from player {} team slot {}.", instanceId, player:getName(), slot)
				end
			end
		end
		Result.free(resultId)
	end

	PokemonTeam.sessions[ownerGuid] = {
		slots = slots,
		dirty = false,
		revision = 1,
	}
	return slots
end

function PokemonTeam.getRevision(player)
	return PokemonTeam.ensureLoaded(player).revision
end

function PokemonTeam.ensureLoaded(player)
	local ownerGuid = player:getGuid()
	return PokemonTeam.sessions[ownerGuid] or (PokemonTeam.load(player) and PokemonTeam.sessions[ownerGuid])
end

function PokemonTeam.list(player)
	local session = PokemonTeam.ensureLoaded(player)
	local result = {}
	for slot = 1, PokemonTeam.MAX_SLOTS do
		result[slot] = session.slots[slot] or false
	end
	return result
end

function PokemonTeam.getSlot(player, slot)
	if not validSlot(slot) then
		return nil, "Team slot must be between 1 and 6."
	end
	local session = PokemonTeam.ensureLoaded(player)
	local instanceId = session.slots[slot]
	if not instanceId then
		return nil, "Team slot is empty."
	end
	return instanceId
end

-- Team owns the ordered selection.  The row in pokemon_instances remains the
-- authority for the actual identity and location; this helper binds both
-- before a live summon projection can be created.
function PokemonTeam.getInstanceForSummon(player, slot)
	local instanceId, reason = PokemonTeam.getSlot(player, slot)
	if not instanceId then
		return nil, nil, reason
	end

	local instance, loadReason = PokemonRepository.load(tostring(instanceId), player:getGuid())
	if not instance then
		return nil, nil, loadReason
	end
	if instance.locationType ~= "team" or tonumber(instance.locationSlot) ~= slot then
		return nil, nil, "Pokemon location changed; refresh the team."
	end
	return instance, tostring(instanceId)
end

function PokemonTeam.findSlotForInstance(player, instanceId)
	instanceId = tostring(instanceId)
	local session = PokemonTeam.ensureLoaded(player)
	for slot = 1, PokemonTeam.MAX_SLOTS do
		if tostring(session.slots[slot] or "") == instanceId then
			return slot
		end
	end
	return nil
end

function PokemonTeam.assignFromCaptureBag(player, bagSlot, teamSlot)
	if PokemonBattleLock then
		local reason = PokemonBattleLock.reason(player)
		if reason then return false, reason end
	end
	if not validSlot(teamSlot) then
		return false, "Team slot must be between 1 and 6."
	end
	local entry = PokemonCaptureBag.getBySlot(player:getGuid(), bagSlot)
	if not entry then
		return false, "Capture Bag slot is empty."
	end

	local session = PokemonTeam.ensureLoaded(player)
	local instanceId = tostring(entry.instanceId)
	if session.slots[teamSlot] then
		return false, "Remove the Pokemon currently occupying this team slot first."
	end
	for slot = 1, PokemonTeam.MAX_SLOTS do
		if session.slots[slot] == instanceId and slot ~= teamSlot then
			return false, "This Pokemon is already assigned to another team slot."
		end
	end

	local instance, reason = PokemonRepository.load(instanceId, player:getGuid())
	if not instance then
		return false, reason
	end
	if instance.locationType ~= PokemonCaptureBag.LOCATION or instance.locationSlot ~= bagSlot then
		return false, "Pokemon location changed; refresh the Capture Bag."
	end
	local moved, moveReason = PokemonRepository.moveLocation(
		instanceId,
		player:getGuid(),
		instance.locationVersion,
		"team",
		teamSlot
	)
	if not moved then
		return false, moveReason
	end

	PokemonCaptureBag.removeInstance(player:getGuid(), instanceId)
	session.slots[teamSlot] = instanceId
	session.dirty = true
	session.revision = session.revision + 1
	if not PokemonTeam.save(player, true) then
		return false, "Pokemon moved, but the team could not be saved."
	end
	return true, string.format("Pokemon moved from Capture Bag slot %d to team slot %d.", bagSlot, teamSlot)
end

function PokemonTeam.remove(player, teamSlot)
	if PokemonBattleLock then
		local reason = PokemonBattleLock.reason(player)
		if reason then return false, reason end
	end
	if not validSlot(teamSlot) then
		return false, "Team slot must be between 1 and 6."
	end
	local session = PokemonTeam.ensureLoaded(player)
	local instanceId = session.slots[teamSlot]
	if not instanceId then
		return false, "Team slot is already empty."
	end

	local destinationSlot, capacity = PokemonCaptureBag.firstFreeSlot(player:getGuid())
	if not destinationSlot then
		return false, string.format("Capture Bag is full (%d/%d).", capacity, capacity)
	end
	local instance, reason = PokemonRepository.load(instanceId, player:getGuid())
	if not instance then
		return false, reason
	end
	if instance.locationType ~= "team" or instance.locationSlot ~= teamSlot then
		return false, "Pokemon location changed; refresh the team."
	end

	-- An active projection still belongs to this same persistent instance.
	-- Persist its HP before changing its Team location, otherwise a failed
	-- recall would leave the database and the map describing different states.
	local active = PokemonSummon.get(player)
	if active and active.instanceId == tostring(instanceId) then
		local dismissed, dismissReason = PokemonSummon.dismiss(player)
		if not dismissed then
			return false, dismissReason or "Could not recall the active Pokemon."
		end
	end
	local moved, moveReason = PokemonRepository.moveLocation(
		instanceId,
		player:getGuid(),
		instance.locationVersion,
		PokemonCaptureBag.LOCATION,
		destinationSlot
	)
	if not moved then
		return false, moveReason
	end

	PokemonCaptureBag.addInstance(moved)
	session.slots[teamSlot] = false
	session.dirty = true
	session.revision = session.revision + 1
	if not PokemonTeam.save(player, true) then
		return false, "Pokemon returned to Capture Bag, but the team could not be saved."
	end
	return true, string.format("Pokemon returned from team slot %d to Capture Bag slot %d.", teamSlot, destinationSlot)
end

local function sqlValue(instanceId)
	if not instanceId then
		return "NULL"
	end
	return tostring(instanceId)
end

function PokemonTeam.save(playerOrGuid, force)
	local ownerGuid = guidOf(playerOrGuid)
	local session = PokemonTeam.sessions[ownerGuid]
	if not session or (not force and not session.dirty) then
		return true
	end

	local query = string.format([[
		INSERT INTO `pokemon_teams`
			(`player_id`, `slot_1`, `slot_2`, `slot_3`, `slot_4`, `slot_5`, `slot_6`)
		VALUES
			(%d, %s, %s, %s, %s, %s, %s)
		ON DUPLICATE KEY UPDATE
			`slot_1` = VALUES(`slot_1`),
			`slot_2` = VALUES(`slot_2`),
			`slot_3` = VALUES(`slot_3`),
			`slot_4` = VALUES(`slot_4`),
			`slot_5` = VALUES(`slot_5`),
			`slot_6` = VALUES(`slot_6`);
	]],
		ownerGuid,
		sqlValue(session.slots[1]),
		sqlValue(session.slots[2]),
		sqlValue(session.slots[3]),
		sqlValue(session.slots[4]),
		sqlValue(session.slots[5]),
		sqlValue(session.slots[6])
	)
	if not db.query(query) then
		logger.error("[PokemonTeam] Failed to save team for player GUID {}.", ownerGuid)
		return false
	end
	session.dirty = false
	return true
end

function PokemonTeam.saveAll(force)
	local success = true
	for ownerGuid in pairs(PokemonTeam.sessions) do
		if not PokemonTeam.save(ownerGuid, force == true) then
			success = false
		end
	end
	return success
end

function PokemonTeam.unload(player)
	local ownerGuid = player:getGuid()
	if not PokemonTeam.save(ownerGuid, true) then
		return false
	end
	PokemonTeam.sessions[ownerGuid] = nil
	return true
end
