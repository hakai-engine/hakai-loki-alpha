function onUpdateDatabase()
	logger.info("Updating database to version 65 (repair Pokemon Team table)")

	if not db.tableExists("pokemon_teams") then
		local created = db.query([[
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
		if not created then
			logger.error("Migration 65 could not create pokemon_teams.")
			return false
		end
	end

	if not db.tableExists("pokemon_teams") then
		logger.error("Migration 65 finished without pokemon_teams being available.")
		return false
	end

	return true
end
