return {
	id = 66,
	name = "Machop",
	types = { "fighting" },
	baseStats = {
		hp = 70,
		attack = 80,
		defense = 50,
		specialAttack = 35,
		specialDefense = 35,
		speed = 35,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 180,
	baseExperience = 61,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 67, method = "level-up", level = 28 },
	evolutions = { { speciesId = 67, method = "level-up", level = 28 } },
	runtime = { placeholder = false, lookType = 3066, level = 5 },
}
