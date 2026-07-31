return {
	id = 23,
	name = "Ekans",
	types = { "poison" },
	baseStats = {
		hp = 35,
		attack = 60,
		defense = 44,
		specialAttack = 40,
		specialDefense = 54,
		speed = 55,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 58,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 24, method = "level-up", level = 22 },
	evolutions = { { speciesId = 24, method = "level-up", level = 22 } },
	runtime = { placeholder = false, lookType = 3023, level = 5 },
}
