function onUpdateDatabase()
	logger.info("Updating database to version 64 (Pokemon Team)")

	if db.tableExists("pokemon_teams") then
		logger.warn("Table pokemon_teams already exists, skipping migration")
		return true
	end

	return db.query([[
		CREATE TABLE `pokemon_teams` (
			`player_id` int(11) NOT NULL,
			`slot_1` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`slot_2` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`slot_3` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`slot_4` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`slot_5` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`slot_6` bigint(20) UNSIGNED NULL DEFAULT NULL,
			`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`player_id`),
			CONSTRAINT `pokemon_teams_player_fk`
				FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	]])
end
