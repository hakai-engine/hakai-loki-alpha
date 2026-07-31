return {
	id = 125,
	name = "Electabuzz",
	types = { "electric" },
	baseStats = {
		hp = 65,
		attack = 83,
		defense = 57,
		specialAttack = 95,
		specialDefense = 85,
		speed = 105,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 45,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 466, method = "trade", item = "electirizer" },
	evolutions = { { speciesId = 466, method = "trade", item = "electirizer" } },
	runtime = { placeholder = false, lookType = 3125, level = 20 },
}
