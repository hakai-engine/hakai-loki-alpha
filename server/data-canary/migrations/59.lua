function onUpdateDatabase()
	logger.info("Updating database to version 59 (add Pokemon instances)")

	if db.tableExists("pokemon_instances") then
		logger.warn("Table pokemon_instances already exists, skipping migration")
		return true
	end

	if
		not db.query([[
		CREATE TABLE `pokemon_instances` (
			`id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
			`schema_version` smallint(5) UNSIGNED NOT NULL DEFAULT '1',
			`owner_id` int(11) NOT NULL,
			`species_id` smallint(5) UNSIGNED NOT NULL,
			`gender` varchar(12) NOT NULL,
			`nature` varchar(12) NOT NULL,
			`level` smallint(5) UNSIGNED NOT NULL DEFAULT '1',
			`experience` bigint(20) UNSIGNED NOT NULL DEFAULT '0',
			`current_hp` int(10) UNSIGNED DEFAULT NULL,
			`max_hp` int(10) UNSIGNED DEFAULT NULL,
			`iv_hp` tinyint(3) UNSIGNED NOT NULL,
			`iv_attack` tinyint(3) UNSIGNED NOT NULL,
			`iv_defense` tinyint(3) UNSIGNED NOT NULL,
			`iv_special_attack` tinyint(3) UNSIGNED NOT NULL,
			`iv_special_defense` tinyint(3) UNSIGNED NOT NULL,
			`iv_speed` tinyint(3) UNSIGNED NOT NULL,
			`origin_method` varchar(24) NOT NULL DEFAULT 'capture',
			`state` varchar(16) NOT NULL DEFAULT 'ready',
			`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `pokemon_instances_owner_id` (`owner_id`),
			KEY `pokemon_instances_owner_state` (`owner_id`, `state`),
			KEY `pokemon_instances_species_id` (`species_id`),
			CONSTRAINT `pokemon_instances_owner_fk`
				FOREIGN KEY (`owner_id`) REFERENCES `players` (`id`)
				ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	]])
	then
		logger.error("Failed to create pokemon_instances table.")
		return false
	end

	return true
end
