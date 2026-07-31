function onUpdateDatabase()
    logger.info("Updating database to version 60 (durable Pokemon capture deliveries)")
    if db.tableExists("pokemon_capture_deliveries") then return true end
    return db.query([[
        CREATE TABLE `pokemon_capture_deliveries` (
            `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            `player_id` int(11) NOT NULL,
            `instance_id` bigint(20) UNSIGNED NOT NULL,
            `ball_item_id` int(10) UNSIGNED NOT NULL,
            `trainer_name` varchar(255) NOT NULL,
            `deliver_after` timestamp(3) NOT NULL,
            `delivered_at` timestamp(3) NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `pokemon_capture_delivery_instance` (`instance_id`),
            KEY `pokemon_capture_delivery_player_pending` (`player_id`, `delivered_at`, `deliver_after`),
            CONSTRAINT `pokemon_capture_delivery_player_fk` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
            CONSTRAINT `pokemon_capture_delivery_instance_fk` FOREIGN KEY (`instance_id`) REFERENCES `pokemon_instances` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end
