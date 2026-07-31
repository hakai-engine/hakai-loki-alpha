return {
	id = 7,
	name = "Squirtle",
	types = { "water" },
	baseStats = {
		hp = 44,
		attack = 48,
		defense = 65,
		specialAttack = 50,
		specialDefense = 64,
		speed = 43,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 63,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 8, method = "level-up", level = 16 },
	evolutions = { { speciesId = 8, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3007, level = 5 },
}
