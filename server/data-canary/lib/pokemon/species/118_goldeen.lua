return {
	id = 118,
	name = "Goldeen",
	types = { "water" },
	baseStats = {
		hp = 45,
		attack = 67,
		defense = 60,
		specialAttack = 35,
		specialDefense = 50,
		speed = 63,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 225,
	baseExperience = 64,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 119, method = "level-up", level = 33 },
	evolutions = { { speciesId = 119, method = "level-up", level = 33 } },
	runtime = { placeholder = false, lookType = 3118, level = 5 },
}
