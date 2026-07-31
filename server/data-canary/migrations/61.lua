function onUpdateDatabase()
	logger.info("Updating database to version 61 (Trainer vocation sample)")

	if not db.tableExists("players") then
		logger.error("Cannot create Trainer Sample: players table is missing")
		return false
	end

	return db.query([[
		INSERT INTO `players`
			(`name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`,
			 `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`,
			 `maglevel`, `mana`, `manamax`, `manaspent`, `town_id`, `conditions`, `cap`,
			 `sex`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`,
			 `skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`)
		SELECT
			'Trainer Sample', `group_id`, `account_id`, `level`, 11, `health`, `healthmax`,
			`experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`,
			`maglevel`, `mana`, `manamax`, `manaspent`, `town_id`, `conditions`, `cap`,
			`sex`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`,
			`skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`
		FROM `players`
		WHERE `name` = 'Druid Sample'
		  AND NOT EXISTS (SELECT 1 FROM `players` WHERE `name` = 'Trainer Sample')
		LIMIT 1;
	]])
end
