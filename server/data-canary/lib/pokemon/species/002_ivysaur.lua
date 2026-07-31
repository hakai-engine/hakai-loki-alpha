return {
	id = 2,
	name = "Ivysaur",
	types = { "grass", "poison" },
	baseStats = {
		hp = 60,
		attack = 62,
		defense = 63,
		specialAttack = 80,
		specialDefense = 80,
		speed = 60,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 3, method = "level-up", level = 32 },
	evolutions = { { speciesId = 3, method = "level-up", level = 32 } },
	runtime = { placeholder = false, lookType = 3002, level = 20 },
}
