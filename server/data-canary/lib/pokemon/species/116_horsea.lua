return {
	id = 116,
	name = "Horsea",
	types = { "water" },
	baseStats = {
		hp = 30,
		attack = 40,
		defense = 70,
		specialAttack = 70,
		specialDefense = 25,
		speed = 60,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 225,
	baseExperience = 59,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 117, method = "level-up", level = 32 },
	evolutions = { { speciesId = 117, method = "level-up", level = 32 } },
	runtime = { placeholder = false, lookType = 3116, level = 5 },
}
