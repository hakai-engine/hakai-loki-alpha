function onUpdateDatabase()
	logger.info("Updating database to version 67 (make Capture Bag and team locations exclusive)")

	return db.query([[
		UPDATE `pokemon_instances` AS `instance`
		INNER JOIN `pokemon_teams` AS `team`
			ON `team`.`player_id` = `instance`.`owner_id`
			AND `instance`.`id` IN (
				`team`.`slot_1`, `team`.`slot_2`, `team`.`slot_3`,
				`team`.`slot_4`, `team`.`slot_5`, `team`.`slot_6`
			)
		SET `instance`.`location_type` = 'team',
			`instance`.`location_slot` = CASE
				WHEN `instance`.`id` = `team`.`slot_1` THEN 1
				WHEN `instance`.`id` = `team`.`slot_2` THEN 2
				WHEN `instance`.`id` = `team`.`slot_3` THEN 3
				WHEN `instance`.`id` = `team`.`slot_4` THEN 4
				WHEN `instance`.`id` = `team`.`slot_5` THEN 5
				WHEN `instance`.`id` = `team`.`slot_6` THEN 6
			END,
			`instance`.`location_version` = `instance`.`location_version` + 1
		WHERE `instance`.`location_type` = 'capture_bag';
	]])
end
