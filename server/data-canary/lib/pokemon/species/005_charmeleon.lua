return {
	id = 5,
	name = "Charmeleon",
	types = { "fire" },
	baseStats = {
		hp = 58,
		attack = 64,
		defense = 58,
		specialAttack = 80,
		specialDefense = 65,
		speed = 80,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 6, method = "level-up", level = 36 },
	evolutions = { { speciesId = 6, method = "level-up", level = 36 } },
	runtime = { placeholder = false, lookType = 3005, level = 20 },
}
