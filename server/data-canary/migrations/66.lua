local function firstFreeCaptureBagSlot(ownerGuid, capacity)
	local occupied = {}
	local resultId = db.storeQuery(string.format([[
		SELECT `location_slot`
		FROM `pokemon_instances`
		WHERE `owner_id` = %d
			AND `location_type` = 'capture_bag'
			AND `location_slot` IS NOT NULL;
	]], ownerGuid))
	if resultId then
		repeat
			occupied[Result.getNumber(resultId, "location_slot")] = true
		until not Result.next(resultId)
		Result.free(resultId)
	end

	for slot = 1, capacity do
		if not occupied[slot] then
			return slot
		end
	end
	return nil
end

function onUpdateDatabase()
	logger.info("Updating database to version 66 (move legacy starters into Capture Bag)")

	local starters = {}
	local resultId = db.storeQuery([[
		SELECT `choice`.`player_id`, `choice`.`instance_id`
		FROM `pokemon_starter_choices` AS `choice`
		INNER JOIN `pokemon_instances` AS `instance`
			ON `instance`.`id` = `choice`.`instance_id`
			AND `instance`.`owner_id` = `choice`.`player_id`
		WHERE `instance`.`location_type` = 'legacy_ball';
	]])
	if resultId then
		repeat
			starters[#starters + 1] = {
				ownerGuid = Result.getNumber(resultId, "player_id"),
				instanceId = Result.getString(resultId, "instance_id"),
			}
		until not Result.next(resultId)
		Result.free(resultId)
	end

	for _, starter in ipairs(starters) do
		local slot = firstFreeCaptureBagSlot(starter.ownerGuid, 20)
		if not slot then
			logger.error("Migration 66 found no Capture Bag slot for starter instance {} (player {}).", starter.instanceId, starter.ownerGuid)
			return false
		end
		if not db.query(string.format([[
			UPDATE `pokemon_instances`
			SET `location_type` = 'capture_bag',
				`location_slot` = %d,
				`location_version` = `location_version` + 1
			WHERE `id` = %s
				AND `owner_id` = %d
				AND `location_type` = 'legacy_ball';
		]], slot, starter.instanceId, starter.ownerGuid)) then
			logger.error("Migration 66 could not move starter instance {} into Capture Bag.", starter.instanceId)
			return false
		end
	end

	logger.info("Migration 66 moved {} legacy starter Pokemon into Capture Bag.", #starters)
	return true
end
