return {
	id = 84,
	name = "Doduo",
	types = { "normal", "flying" },
	baseStats = {
		hp = 35,
		attack = 85,
		defense = 45,
		specialAttack = 35,
		specialDefense = 35,
		speed = 75,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 62,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 85, method = "level-up", level = 31 },
	evolutions = { { speciesId = 85, method = "level-up", level = 31 } },
	runtime = { placeholder = false, lookType = 3084, level = 5 },
}
