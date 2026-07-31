function onUpdateDatabase()
	logger.info("Updating database to version 63 (Pokemon Capture Bag)")

	if not db.tableExists("pokemon_capture_bags") then
		if not db.query([[
			CREATE TABLE `pokemon_capture_bags` (
				`account_id` int(11) UNSIGNED NOT NULL,
				`capacity` smallint(5) UNSIGNED NOT NULL DEFAULT '20',
				`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
				PRIMARY KEY (`account_id`),
				CONSTRAINT `pokemon_capture_bags_account_fk`
					FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
				CONSTRAINT `pokemon_capture_bags_capacity_check`
					CHECK (`capacity` >= 1 AND `capacity` <= 2000)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
		]]) then
			return false
		end
	end

	if not db.query([[
		ALTER TABLE `pokemon_instances`
			ADD COLUMN `location_type` varchar(24) NOT NULL DEFAULT 'legacy_ball' AFTER `state`,
			ADD COLUMN `location_slot` smallint(5) UNSIGNED NULL DEFAULT NULL AFTER `location_type`,
			ADD COLUMN `ball_item_id` int(10) UNSIGNED NULL DEFAULT NULL AFTER `location_slot`,
			ADD COLUMN `location_version` int(10) UNSIGNED NOT NULL DEFAULT '1' AFTER `ball_item_id`,
			ADD UNIQUE KEY `pokemon_instances_owner_location_slot`
				(`owner_id`, `location_type`, `location_slot`),
			ADD KEY `pokemon_instances_owner_location`
				(`owner_id`, `location_type`),
			ADD CONSTRAINT `pokemon_instances_location_type_check`
				CHECK (`location_type` IN ('capture_bag', 'team', 'storage', 'trade', 'market', 'legacy_ball')),
			ADD CONSTRAINT `pokemon_instances_location_slot_check`
				CHECK (
					(`location_type` IN ('capture_bag', 'team', 'storage') AND `location_slot` IS NOT NULL)
					OR
					(`location_type` IN ('trade', 'market', 'legacy_ball') AND `location_slot` IS NULL)
				);
	]]) then
		logger.error("Failed to add Capture Bag location fields to pokemon_instances.")
		return false
	end

	return db.query([[
		INSERT IGNORE INTO `pokemon_capture_bags` (`account_id`, `capacity`)
		SELECT `id`, 20 FROM `accounts`;
	]])
end
