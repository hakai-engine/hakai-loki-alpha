return {
	id = 56,
	name = "Mankey",
	types = { "fighting" },
	baseStats = {
		hp = 40,
		attack = 80,
		defense = 35,
		specialAttack = 35,
		specialDefense = 45,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 61,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 57, method = "level-up", level = 28 },
	evolutions = { { speciesId = 57, method = "level-up", level = 28 } },
	runtime = { placeholder = false, lookType = 3056, level = 5 },
}
