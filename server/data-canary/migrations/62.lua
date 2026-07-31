function onUpdateDatabase()
	logger.info("Updating database to version 62 (durable Pokemon starter choices)")
	if db.tableExists("pokemon_starter_choices") then return true end

	return db.query([[
		CREATE TABLE `pokemon_starter_choices` (
			`player_id` int(11) NOT NULL,
			`instance_id` bigint(20) UNSIGNED NOT NULL,
			`species_id` smallint(5) UNSIGNED NOT NULL,
			`chosen_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`player_id`),
			UNIQUE KEY `pokemon_starter_choices_instance` (`instance_id`),
			CONSTRAINT `pokemon_starter_choices_player_fk`
				FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
			CONSTRAINT `pokemon_starter_choices_instance_fk`
				FOREIGN KEY (`instance_id`) REFERENCES `pokemon_instances` (`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	]])
end
