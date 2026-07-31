return {
	id = 72,
	name = "Tentacool",
	types = { "water", "poison" },
	baseStats = {
		hp = 40,
		attack = 40,
		defense = 35,
		specialAttack = 50,
		specialDefense = 100,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 67,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 73, method = "level-up", level = 30 },
	evolutions = { { speciesId = 73, method = "level-up", level = 30 } },
	runtime = { placeholder = false, lookType = 3072, level = 5 },
}
