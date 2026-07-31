return {
	id = 46,
	name = "Paras",
	types = { "bug", "grass" },
	baseStats = {
		hp = 35,
		attack = 70,
		defense = 55,
		specialAttack = 45,
		specialDefense = 55,
		speed = 25,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 57,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 47, method = "level-up", level = 24 },
	evolutions = { { speciesId = 47, method = "level-up", level = 24 } },
	runtime = { placeholder = false, lookType = 3046, level = 5 },
}
