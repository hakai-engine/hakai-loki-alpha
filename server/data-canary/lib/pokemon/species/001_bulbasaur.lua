return {
	id = 1,
	name = "Bulbasaur",
	types = { "grass", "poison" },
	baseStats = {
		hp = 45,
		attack = 49,
		defense = 49,
		specialAttack = 65,
		specialDefense = 65,
		speed = 45,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 64,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 2, method = "level-up", level = 16 },
	evolutions = { { speciesId = 2, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3001, level = 5 },
}
