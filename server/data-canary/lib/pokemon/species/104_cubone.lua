return {
	id = 104,
	name = "Cubone",
	types = { "ground" },
	baseStats = {
		hp = 50,
		attack = 50,
		defense = 95,
		specialAttack = 40,
		specialDefense = 50,
		speed = 35,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 64,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 105, method = "level-up", level = 28 },
	evolutions = { { speciesId = 105, method = "level-up", level = 28 } },
	runtime = { placeholder = false, lookType = 3104, level = 5 },
}
