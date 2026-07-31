function onUpdateDatabase()
	logger.info("Updating database to version 68 (Trainer Sample default outfit)")

	if not db.tableExists("players") then
		logger.error("Cannot update Trainer Sample outfit: players table is missing")
		return false
	end

	return db.query([[
		UPDATE `players`
		SET `looktype` = 4210,
			`lookhead` = 0,
			`lookbody` = 0,
			`looklegs` = 0,
			`lookfeet` = 0,
			`lookaddons` = 0
		WHERE `name` = 'Trainer Sample';
	]])
end
