return {
	id = 52,
	name = "Meowth",
	types = { "normal" },
	baseStats = {
		hp = 40,
		attack = 45,
		defense = 35,
		specialAttack = 40,
		specialDefense = 40,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 58,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 53, method = "level-up", level = 28 },
	evolutions = { { speciesId = 53, method = "level-up", level = 28 }, { speciesId = 863, method = "level-up", level = 28 } },
	runtime = { placeholder = false, lookType = 3052, level = 5 },
}
