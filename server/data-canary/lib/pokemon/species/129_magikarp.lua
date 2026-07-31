return {
	id = 129,
	name = "Magikarp",
	types = { "water" },
	baseStats = {
		hp = 20,
		attack = 10,
		defense = 55,
		specialAttack = 15,
		specialDefense = 20,
		speed = 80,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 40,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 130, method = "level-up", level = 20 },
	evolutions = { { speciesId = 130, method = "level-up", level = 20 } },
	runtime = { placeholder = false, lookType = 3129, level = 5 },
}
