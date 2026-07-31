local function schemaObjectExists(query)
	local resultId = db.storeQuery(query)
	if not resultId then
		return false
	end
	Result.free(resultId)
	return true
end

function onUpdateDatabase()
	logger.info("Updating database to version 69 (secure account session ownership)")

	if not db.tableExists("accounts") or not db.tableExists("account_sessions") then
		logger.error("Migration 69 requires accounts and account_sessions.")
		return false
	end

	if not db.query([[
		DELETE `session`
		FROM `account_sessions` AS `session`
		LEFT JOIN `accounts` AS `account`
			ON `account`.`id` = `session`.`account_id`
		WHERE `account`.`id` IS NULL;
	]]) then
		logger.error("Migration 69 could not remove orphaned account sessions.")
		return false
	end

	local hasAccountIndex = schemaObjectExists([[
		SELECT 1
		FROM `information_schema`.`STATISTICS`
		WHERE `TABLE_SCHEMA` = DATABASE()
			AND `TABLE_NAME` = 'account_sessions'
			AND `INDEX_NAME` = 'account_sessions_account_id_idx'
		LIMIT 1;
	]])
	if not hasAccountIndex and not db.query([[
		ALTER TABLE `account_sessions`
			ADD INDEX `account_sessions_account_id_idx` (`account_id`);
	]]) then
		logger.error("Migration 69 could not index account_sessions.account_id.")
		return false
	end

	local hasAccountForeignKey = schemaObjectExists([[
		SELECT 1
		FROM `information_schema`.`TABLE_CONSTRAINTS`
		WHERE `CONSTRAINT_SCHEMA` = DATABASE()
			AND `TABLE_NAME` = 'account_sessions'
			AND `CONSTRAINT_NAME` = 'account_sessions_account_fk'
			AND `CONSTRAINT_TYPE` = 'FOREIGN KEY'
		LIMIT 1;
	]])
	if not hasAccountForeignKey and not db.query([[
		ALTER TABLE `account_sessions`
			ADD CONSTRAINT `account_sessions_account_fk`
			FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
			ON DELETE CASCADE;
	]]) then
		logger.error("Migration 69 could not add the account_sessions foreign key.")
		return false
	end

	return true
end
