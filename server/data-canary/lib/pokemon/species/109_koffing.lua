return {
	id = 109,
	name = "Koffing",
	types = { "poison" },
	baseStats = {
		hp = 40,
		attack = 65,
		defense = 95,
		specialAttack = 60,
		specialDefense = 45,
		speed = 35,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 68,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 110, method = "level-up", level = 35 },
	evolutions = { { speciesId = 110, method = "level-up", level = 35 } },
	runtime = { placeholder = false, lookType = 3109, level = 5 },
}
