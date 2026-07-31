return {
	id = 4,
	name = "Charmander",
	types = { "fire" },
	baseStats = {
		hp = 39,
		attack = 52,
		defense = 43,
		specialAttack = 60,
		specialDefense = 50,
		speed = 65,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 62,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 5, method = "level-up", level = 16 },
	evolutions = { { speciesId = 5, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3004, level = 5 },
}
