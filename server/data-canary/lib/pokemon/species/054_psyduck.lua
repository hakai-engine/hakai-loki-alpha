return {
	id = 54,
	name = "Psyduck",
	types = { "water" },
	baseStats = {
		hp = 50,
		attack = 52,
		defense = 48,
		specialAttack = 65,
		specialDefense = 50,
		speed = 55,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 64,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 55, method = "level-up", level = 33 },
	evolutions = { { speciesId = 55, method = "level-up", level = 33 } },
	runtime = { placeholder = false, lookType = 3054, level = 5 },
}
