PokemonRepository = {}

-- Rebuild missing vitals and reconcile derived maximum HP when species, level,
-- IVs, nature or the gender bucket changes. Preserve the current-health ratio;
-- a valid fainted Pokemon (0/N) must stay fainted.
function PokemonRepository.normalizeVitals(instance)
	local species = instance and PokemonSpecies.get(instance.speciesId)
	if not species or type(instance.level) ~= "number" or type(instance.ivs) ~= "table" then
		return false
	end

	local changed = false
	local expectedMaximum = math.max(
		PokemonStats.calculate(species, instance.level, instance.ivs, instance.nature, instance.gender).hp,
		1
	)
	local maximum = tonumber(instance.maxHp)
	if not maximum or maximum <= 0 then
		instance.maxHp = expectedMaximum
		instance.currentHp = instance.maxHp
		instance.state = "ready"
		return true
	end

	maximum = math.floor(maximum)
	local current = tonumber(instance.currentHp)
	if current == nil or current < 0 then
		instance.currentHp = expectedMaximum
		instance.state = "ready"
		changed = true
	else
		instance.currentHp = math.floor(current)
	end

	if maximum ~= expectedMaximum then
		local healthRatio = math.min(instance.currentHp / maximum, 1)
		instance.maxHp = expectedMaximum
		if instance.currentHp == 0 or instance.state == "fainted" then
			instance.currentHp = 0
		else
			instance.currentHp = math.max(1, math.min(expectedMaximum, math.floor(expectedMaximum * healthRatio + 0.5)))
		end
		changed = true
	else
		instance.maxHp = maximum
		if instance.currentHp > instance.maxHp then
			instance.currentHp = instance.maxHp
			changed = true
		end
	end
	return changed
end

local function readInstance(resultId)
	local currentHp = Result.getNumber(resultId, "current_hp")
	local maxHp = Result.getNumber(resultId, "max_hp")
	local instance = {
		schemaVersion = Result.getNumber(resultId, "schema_version"),
		instanceId = Result.getString(resultId, "id"),
		ownerGuid = Result.getNumber(resultId, "owner_id"),
		speciesId = Result.getNumber(resultId, "species_id"),
		gender = Result.getString(resultId, "gender"),
		nature = Result.getString(resultId, "nature"),
		level = Result.getNumber(resultId, "level"),
		experience = Result.getNumber(resultId, "experience"),
		currentHp = currentHp >= 0 and currentHp or nil,
		maxHp = maxHp >= 0 and maxHp or nil,
		ivs = {
			hp = Result.getNumber(resultId, "iv_hp"),
			attack = Result.getNumber(resultId, "iv_attack"),
			defense = Result.getNumber(resultId, "iv_defense"),
			specialAttack = Result.getNumber(resultId, "iv_special_attack"),
			specialDefense = Result.getNumber(resultId, "iv_special_defense"),
			speed = Result.getNumber(resultId, "iv_speed"),
		},
		moves = {},
		origin = {
			method = Result.getString(resultId, "origin_method"),
			capturedAt = Result.getNumber(resultId, "created_at_unix"),
		},
		state = Result.getString(resultId, "state"),
		locationType = Result.getString(resultId, "location_type"),
		locationSlot = Result.getNumber(resultId, "location_slot"),
		ballItemId = Result.getNumber(resultId, "ball_item_id"),
		locationVersion = Result.getNumber(resultId, "location_version"),
	}
	return instance
end

function PokemonRepository.createCaptured(encounter, ownerGuid, originMethod, ballItemId)
	if not db.tableExists("pokemon_instances") then
		return nil, "pokemon_instances table is missing; run database migrations"
	end
	if not db.tableExists("pokemon_capture_bags") then
		return nil, "pokemon_capture_bags table is missing; run database migrations"
	end

	local locationSlot, capacity = PokemonCaptureBag.firstFreeSlot(ownerGuid)
	if not locationSlot then
		return nil, string.format("Capture Bag is full (%d/%d)", capacity, capacity)
	end

	-- Nature was created exactly once with the wild encounter. Capturing
	-- persists that same individual identity and never rerolls it.
	local instance = PokemonInstance.createCaptured(encounter, ownerGuid, "pending")
	instance.origin.method = originMethod or "capture"
	local query = string.format(
		[[
			INSERT INTO `pokemon_instances`
				(`schema_version`, `owner_id`, `species_id`, `gender`, `nature`, `level`, `experience`,
				 `current_hp`, `max_hp`, `iv_hp`, `iv_attack`, `iv_defense`, `iv_special_attack`,
				 `iv_special_defense`, `iv_speed`, `origin_method`, `state`,
				 `location_type`, `location_slot`, `ball_item_id`)
			VALUES
				(%d, %d, %d, %s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %s, %s, %s, %d, %s);
		]],
		instance.schemaVersion,
		instance.ownerGuid,
		instance.speciesId,
		db.escapeString(instance.gender),
		db.escapeString(instance.nature),
		instance.level,
		instance.experience,
		instance.currentHp,
		instance.maxHp,
		instance.ivs.hp,
		instance.ivs.attack,
		instance.ivs.defense,
		instance.ivs.specialAttack,
		instance.ivs.specialDefense,
		instance.ivs.speed,
		db.escapeString(instance.origin.method),
		db.escapeString(instance.state),
		db.escapeString(PokemonCaptureBag.LOCATION),
		locationSlot,
		ballItemId and tostring(ballItemId) or "NULL"
	)

	if not db.query(query) then
		return nil, "failed to persist captured Pokemon instance"
	end

	local insertedId = db.lastInsertId()
	if type(insertedId) ~= "number" or insertedId <= 0 then
		return nil, "instance inserted but lastInsertId is invalid"
	end
	instance.instanceId = string.format("%.0f", insertedId)
	instance.locationType = PokemonCaptureBag.LOCATION
	instance.locationSlot = locationSlot
	instance.ballItemId = ballItemId
	PokemonCaptureBag.addInstance(instance)
	return instance
end

function PokemonRepository.createStarter(encounter, ownerGuid, ballItemId)
	return PokemonRepository.createCaptured(encounter, ownerGuid, "starter", ballItemId)
end

function PokemonRepository.hasStarterChoice(playerGuid)
	assert(type(playerGuid) == "number" and playerGuid > 0, "playerGuid must be positive")
	if not db.tableExists("pokemon_starter_choices") then return false end

	local resultId = db.storeQuery(string.format(
		"SELECT `instance_id` FROM `pokemon_starter_choices` WHERE `player_id` = %d LIMIT 1;",
		playerGuid
	))
	if not resultId then return false end
	Result.free(resultId)
	return true
end

function PokemonRepository.recordStarterChoice(playerGuid, instanceId, speciesId)
	assert(type(playerGuid) == "number" and playerGuid > 0, "playerGuid must be positive")
	assert(type(instanceId) == "string" and instanceId:match("^%d+$"), "instanceId must be a numeric string")
	assert(type(speciesId) == "number" and speciesId > 0, "speciesId must be positive")
	if not db.tableExists("pokemon_starter_choices") then
		return false, "pokemon_starter_choices table is missing; run database migrations"
	end

	local query = string.format(
		[[
			INSERT INTO `pokemon_starter_choices` (`player_id`, `instance_id`, `species_id`)
			VALUES (%d, %s, %d);
		]],
		playerGuid,
		instanceId,
		speciesId
	)
	if not db.query(query) then return false, "starter choice was already recorded or could not be persisted" end
	return true
end

function PokemonRepository.deleteUnclaimedStarter(instanceId, ownerGuid)
	assert(type(instanceId) == "string" and instanceId:match("^%d+$"), "instanceId must be a numeric string")
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")
	local deleted = db.query(string.format(
		[[
			DELETE FROM `pokemon_instances`
			WHERE `id` = %s AND `owner_id` = %d AND `origin_method` = 'starter' AND `state` = 'ready';
		]],
		instanceId,
		ownerGuid
	))
	if deleted then
		PokemonCaptureBag.removeInstance(ownerGuid, instanceId)
	end
	return deleted
end

function PokemonRepository.load(instanceId, ownerGuid)
	assert(type(instanceId) == "string" and instanceId:match("^%d+$"), "instanceId must be a numeric string")
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")

	local query = string.format(
		[[
			SELECT `id`, `schema_version`, `owner_id`, `species_id`, `gender`, `nature`, `level`,
			       `experience`, COALESCE(`current_hp`, -1) AS `current_hp`,
			       COALESCE(`max_hp`, -1) AS `max_hp`, `iv_hp`, `iv_attack`, `iv_defense`,
			       `iv_special_attack`, `iv_special_defense`, `iv_speed`, `origin_method`, `state`,
			       `location_type`, COALESCE(`location_slot`, 0) AS `location_slot`,
			       COALESCE(`ball_item_id`, 0) AS `ball_item_id`,
			       `location_version`,
			       UNIX_TIMESTAMP(`created_at`) AS `created_at_unix`
			FROM `pokemon_instances`
			WHERE `id` = %s AND `owner_id` = %d
			LIMIT 1;
		]],
		instanceId,
		ownerGuid
	)
	local resultId = db.storeQuery(query)
	if not resultId then
		return nil, "Pokemon instance not found for owner"
	end

	local instance = readInstance(resultId)
	Result.free(resultId)
	local repairedVitals = PokemonRepository.normalizeVitals(instance)
	local repairedExperience = PokemonProgression.normalizeExperience(instance)
	local valid, reason = PokemonInstance.validate(instance)
	if not valid then
		return nil, reason
	end
	if repairedVitals or repairedExperience then
		local persisted, persistReason = PokemonRepository.updateVitals(instance)
		if not persisted then
			return nil, persistReason or "failed to persist repaired Pokemon vitals"
		end
		logger.warn(
			"[PokemonRepository] Repaired derived state for instance {} (species {}, owner {}): HP {}/{}, XP {}.",
			instance.instanceId,
			instance.speciesId,
			instance.ownerGuid,
			instance.currentHp,
			instance.maxHp,
			instance.experience
		)
	end
	return instance
end

function PokemonRepository.loadCaptureBagSlot(ownerGuid, slot)
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")
	assert(type(slot) == "number" and slot > 0 and slot == math.floor(slot), "slot must be a positive integer")
	local resultId = db.storeQuery(string.format([[
		SELECT `id`
		FROM `pokemon_instances`
		WHERE `owner_id` = %d AND `location_type` = %s AND `location_slot` = %d
		LIMIT 1;
	]], ownerGuid, db.escapeString(PokemonCaptureBag.LOCATION), slot))
	if not resultId then
		return nil, "Capture Bag slot is empty"
	end
	local instanceId = Result.getString(resultId, "id")
	Result.free(resultId)
	return PokemonRepository.load(instanceId, ownerGuid)
end

local LOCATION_TYPES = {
	capture_bag = true,
	team = true,
	storage = true,
	trade = true,
	market = true,
	legacy_ball = true,
}

function PokemonRepository.moveLocation(instanceId, ownerGuid, expectedVersion, locationType, locationSlot)
	assert(type(instanceId) == "string" and instanceId:match("^%d+$"), "instanceId must be a numeric string")
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")
	assert(type(expectedVersion) == "number" and expectedVersion > 0, "expectedVersion must be positive")
	assert(LOCATION_TYPES[locationType], "unsupported Pokemon location type")

	local requiresSlot = locationType == "capture_bag" or locationType == "team" or locationType == "storage"
	if requiresSlot then
		assert(type(locationSlot) == "number" and locationSlot > 0 and locationSlot == math.floor(locationSlot), "destination requires a positive slot")
	else
		locationSlot = nil
	end

	local query = string.format([[
		UPDATE `pokemon_instances`
		SET `location_type` = %s,
		    `location_slot` = %s,
		    `location_version` = `location_version` + 1
		WHERE `id` = %s
		  AND `owner_id` = %d
		  AND `location_version` = %d
		  AND `state` = 'ready';
	]],
		db.escapeString(locationType),
		locationSlot and tostring(locationSlot) or "NULL",
		instanceId,
		ownerGuid,
		expectedVersion
	)
	if not db.query(query) then
		return nil, "Pokemon location update failed"
	end

	local instance, reason = PokemonRepository.load(instanceId, ownerGuid)
	if not instance then
		return nil, reason
	end
	if instance.locationVersion ~= expectedVersion + 1
		or instance.locationType ~= locationType
		or (requiresSlot and instance.locationSlot ~= locationSlot)
	then
		return nil, "Pokemon location changed concurrently; refresh and try again"
	end
	return instance
end

function PokemonRepository.transferOwnership(instanceId, previousOwnerGuid, newOwnerGuid)
	assert(type(instanceId) == "string" and instanceId:match("^%d+$"), "instanceId must be a numeric string")
	assert(type(previousOwnerGuid) == "number" and previousOwnerGuid > 0, "previousOwnerGuid must be positive")
	assert(type(newOwnerGuid) == "number" and newOwnerGuid > 0, "newOwnerGuid must be positive")

	if previousOwnerGuid == newOwnerGuid then
		return PokemonRepository.load(instanceId, newOwnerGuid)
	end

	-- The previous owner is part of the WHERE clause intentionally. A stale or
	-- duplicated Ball cannot take an instance back after the legitimate Ball
	-- has already transferred it to another player.
	local query = string.format(
		[[
			UPDATE `pokemon_instances`
			SET `owner_id` = %d
			WHERE `id` = %s AND `owner_id` = %d AND `state` = 'ready';
		]],
		newOwnerGuid,
		instanceId,
		previousOwnerGuid
	)
	if not db.query(query) then
		return nil, "Pokemon ownership transfer failed"
	end

	local instance = PokemonRepository.load(instanceId, newOwnerGuid)
	if not instance then
		return nil, "This Poke Ball is stale or the Pokemon is not ready for transfer"
	end
	return instance
end

function PokemonRepository.updateVitals(instance)
	local valid, reason = PokemonInstance.validate(instance)
	if not valid then
		return false, reason
	end
	if instance.currentHp == nil or instance.maxHp == nil then
		return false, "currentHp and maxHp are required"
	end
	if instance.currentHp < 0 or instance.maxHp <= 0 or instance.currentHp > instance.maxHp then
		return false, "invalid HP values"
	end

	local query = string.format(
		[[
			UPDATE `pokemon_instances`
		SET `experience` = %d, `current_hp` = %d, `max_hp` = %d, `state` = %s
			WHERE `id` = %s AND `owner_id` = %d;
		]],
		instance.experience,
		instance.currentHp,
		instance.maxHp,
		db.escapeString(instance.state),
		instance.instanceId,
		instance.ownerGuid
	)
	return db.query(query)
end

-- Progression is written atomically against the last loaded level/XP pair.
-- This makes duplicate death callbacks and stale active projections harmless:
-- only the first valid award can advance the persisted instance.
function PokemonRepository.persistProgression(previous, progressed)
	assert(type(previous) == "table" and type(progressed) == "table", "progression persistence requires before and after instances")
	assert(previous.instanceId == progressed.instanceId, "progression must preserve instanceId")
	assert(previous.ownerGuid == progressed.ownerGuid, "progression must preserve ownerGuid")
	local valid, reason = PokemonInstance.validate(progressed)
	if not valid then return nil, reason end

	local query = string.format([[
		UPDATE `pokemon_instances`
		SET `level` = %d,
		    `experience` = %d,
		    `current_hp` = %d,
		    `max_hp` = %d,
		    `state` = %s
		WHERE `id` = %s
		  AND `owner_id` = %d
		  AND `level` = %d
		  AND `experience` = %d;
	]],
		progressed.level, progressed.experience, progressed.currentHp, progressed.maxHp,
		db.escapeString(progressed.state), previous.instanceId, previous.ownerGuid,
		previous.level, previous.experience
	)
	if not db.query(query) then
		return nil, "Pokemon progression update failed or was superseded"
	end
	local persisted, loadReason = PokemonRepository.load(previous.instanceId, previous.ownerGuid)
	if not persisted then return nil, loadReason end
	if persisted.level ~= progressed.level or persisted.experience ~= progressed.experience then
		return nil, "Pokemon progression lost its optimistic update race"
	end
	return persisted
end

function PokemonRepository.persistEvolution(previous, evolved)
	assert(type(previous) == "table" and type(evolved) == "table", "evolution persistence requires before and after instances")
	assert(previous.instanceId == evolved.instanceId, "evolution must preserve instanceId")
	assert(previous.ownerGuid == evolved.ownerGuid, "evolution must preserve ownerGuid")
	assert(previous.speciesId ~= evolved.speciesId, "evolution must change species")

	local query = string.format([[
		UPDATE `pokemon_instances`
		SET `species_id` = %d,
		    `current_hp` = %d,
		    `max_hp` = %d,
		    `location_version` = `location_version` + 1
		WHERE `id` = %s
		  AND `owner_id` = %d
		  AND `species_id` = %d
		  AND `location_version` = %d
		  AND `state` IN ('ready', 'fainted');
	]],
		evolved.speciesId,
		evolved.currentHp,
		evolved.maxHp,
		previous.instanceId,
		previous.ownerGuid,
		previous.speciesId,
		previous.locationVersion
	)
	if not db.query(query) then
		return nil, "Pokemon evolution update failed"
	end

	local persisted, reason = PokemonRepository.load(previous.instanceId, previous.ownerGuid)
	if not persisted then
		return nil, reason
	end
	if persisted.speciesId ~= evolved.speciesId or persisted.locationVersion ~= previous.locationVersion + 1 then
		return nil, "Pokemon evolution lost its optimistic version race"
	end
	if PokemonCaptureBag then
		PokemonCaptureBag.updateInstance(persisted)
	end
	logger.info(
		"[PokemonEvolution] Instance {} owned by {} evolved from species {} to {}.",
		persisted.instanceId,
		persisted.ownerGuid,
		previous.speciesId,
		persisted.speciesId
	)
	return persisted
end

function PokemonRepository.healRoster(ownerGuid)
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")

	-- Repair legacy 0/0 rows before the bulk heal. Otherwise SQL faithfully
	-- assigns current_hp = max_hp = 0 and Nurse Joy can never restore them.
	local instances = {}
	local repairResult = db.storeQuery(string.format([[
		SELECT `id`
		FROM `pokemon_instances`
		WHERE `owner_id` = %d
		  AND `location_type` IN ('capture_bag', 'team');
	]], ownerGuid))
	if repairResult then
		repeat
			instances[#instances + 1] = Result.getString(repairResult, "id")
		until not Result.next(repairResult)
		Result.free(repairResult)
	end
	for _, instanceId in ipairs(instances) do
		local instance, reason = PokemonRepository.load(instanceId, ownerGuid)
		if not instance then
			return false, 0, #instances, reason or "failed to repair Pokemon vitals"
		end
	end

	local totals = { total = 0, injured = 0 }
	local resultId = db.storeQuery(string.format(
		[[
			SELECT
				COUNT(*) AS `total`,
				COALESCE(SUM(`current_hp` < `max_hp` OR `state` <> 'ready'), 0) AS `injured`
			FROM `pokemon_instances`
			WHERE `owner_id` = %d
			  AND `location_type` IN ('capture_bag', 'team');
		]],
		ownerGuid
	))
	if resultId then
		totals.total = Result.getNumber(resultId, "total")
		totals.injured = Result.getNumber(resultId, "injured")
		Result.free(resultId)
	end

	local updated = db.query(string.format(
		[[
			UPDATE `pokemon_instances`
			SET `current_hp` = `max_hp`, `state` = 'ready'
			WHERE `owner_id` = %d
			  AND `location_type` IN ('capture_bag', 'team');
		]],
		ownerGuid
	))
	return updated, totals.injured, totals.total
end

function PokemonRepository.queueCaptureDelivery(instance, trainerName, ballItemId, delayMs)
    if not db.tableExists("pokemon_capture_deliveries") then return nil, "pokemon_capture_deliveries table is missing" end
    local query=string.format([[INSERT INTO `pokemon_capture_deliveries` (`player_id`,`instance_id`,`ball_item_id`,`trainer_name`,`deliver_after`) VALUES (%d,%s,%d,%s,DATE_ADD(NOW(3),INTERVAL %d MICROSECOND));]],instance.ownerGuid,instance.instanceId,ballItemId,db.escapeString(trainerName),delayMs*1000)
    if not db.query(query) then return nil,"failed to queue captured Pokemon delivery" end
    return string.format("%.0f",db.lastInsertId())
end

function PokemonRepository.pendingCaptureDeliveries(ownerGuid)
    local deliveries={}
    if not db.tableExists("pokemon_capture_deliveries") then return deliveries end
    local resultId=db.storeQuery(string.format([[SELECT `id`,`instance_id`,`ball_item_id`,`trainer_name`,GREATEST(0,TIMESTAMPDIFF(MICROSECOND,NOW(3),`deliver_after`)/1000) AS `remaining_ms` FROM `pokemon_capture_deliveries` WHERE `player_id`=%d AND `delivered_at` IS NULL ORDER BY `id`;]],ownerGuid))
    if not resultId then return deliveries end
    repeat
        table.insert(deliveries,{deliveryId=Result.getString(resultId,"id"),instanceId=Result.getString(resultId,"instance_id"),ballItemId=Result.getNumber(resultId,"ball_item_id"),trainerName=Result.getString(resultId,"trainer_name"),remainingMs=math.ceil(Result.getNumber(resultId,"remaining_ms"))})
    until not Result.next(resultId)
    Result.free(resultId); return deliveries
end

function PokemonRepository.markCaptureDelivered(deliveryId,ownerGuid)
    return db.query(string.format([[UPDATE `pokemon_capture_deliveries` SET `delivered_at`=NOW(3) WHERE `id`=%s AND `player_id`=%d AND `delivered_at` IS NULL;]],deliveryId,ownerGuid))
end
