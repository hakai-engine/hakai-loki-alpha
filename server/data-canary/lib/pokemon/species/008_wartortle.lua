return {
	id = 8,
	name = "Wartortle",
	types = { "water" },
	baseStats = {
		hp = 59,
		attack = 63,
		defense = 80,
		specialAttack = 65,
		specialDefense = 80,
		speed = 58,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 9, method = "level-up", level = 36 },
	evolutions = { { speciesId = 9, method = "level-up", level = 36 } },
	runtime = { placeholder = false, lookType = 3008, level = 20 },
}
