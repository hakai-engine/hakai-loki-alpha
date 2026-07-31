return {
	id = 92,
	name = "Gastly",
	types = { "ghost", "poison" },
	baseStats = {
		hp = 30,
		attack = 35,
		defense = 30,
		specialAttack = 100,
		specialDefense = 35,
		speed = 80,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 62,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 93, method = "level-up", level = 25 },
	evolutions = { { speciesId = 93, method = "level-up", level = 25 } },
	runtime = { placeholder = false, lookType = 3092, level = 5 },
}
