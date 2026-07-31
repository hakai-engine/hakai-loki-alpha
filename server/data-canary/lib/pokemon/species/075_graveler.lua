return {
	id = 75,
	name = "Graveler",
	types = { "rock", "ground" },
	baseStats = {
		hp = 55,
		attack = 95,
		defense = 115,
		specialAttack = 45,
		specialDefense = 45,
		speed = 35,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 137,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 76, method = "trade" },
	evolutions = { { speciesId = 76, method = "trade" } },
	runtime = { placeholder = false, lookType = 3075, level = 20 },
}
