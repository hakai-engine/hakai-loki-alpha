return {
	id = 13,
	name = "Weedle",
	types = { "bug", "poison" },
	baseStats = {
		hp = 40,
		attack = 35,
		defense = 30,
		specialAttack = 20,
		specialDefense = 20,
		speed = 50,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 39,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 14, method = "level-up", level = 7 },
	evolutions = { { speciesId = 14, method = "level-up", level = 7 } },
	runtime = { placeholder = false, lookType = 3013, level = 5 },
}
