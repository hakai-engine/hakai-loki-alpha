local function schemaObjectExists(query)
	local resultId = db.storeQuery(query)
	if not resultId then
		return false
	end
	Result.free(resultId)
	return true
end

function onUpdateDatabase()
	logger.info("Updating database to version 70 (enforce SHA-256 account sessions)")

	if not db.tableExists("accounts") or not db.tableExists("account_sessions") then
		logger.error("Migration 70 requires accounts and account_sessions.")
		return false
	end

	if not db.query([[
		DELETE FROM `account_sessions`
		WHERE CHAR_LENGTH(`id`) <> 64
			OR `id` NOT REGEXP '^[0-9a-f]{64}$'
			OR BINARY `id` <> BINARY LOWER(`id`);
	]]) then
		logger.error("Migration 70 could not remove invalid or legacy account session IDs.")
		return false
	end

	if not db.query([[
		ALTER TABLE `account_sessions`
			MODIFY `id` CHAR(64)
			CHARACTER SET ascii
			COLLATE ascii_bin
			NOT NULL;
	]]) then
		logger.error("Migration 70 could not enforce the SHA-256 account session ID column.")
		return false
	end

	local hasExpiresIndex = schemaObjectExists([[
		SELECT 1
		FROM `information_schema`.`STATISTICS`
		WHERE `TABLE_SCHEMA` = DATABASE()
			AND `TABLE_NAME` = 'account_sessions'
			AND `INDEX_NAME` = 'account_sessions_expires_idx'
		LIMIT 1;
	]])
	if not hasExpiresIndex and not db.query([[
		ALTER TABLE `account_sessions`
			ADD INDEX `account_sessions_expires_idx` (`expires`);
	]]) then
		logger.error("Migration 70 could not index account_sessions.expires.")
		return false
	end

	return true
end
