return {
	id = 88,
	name = "Grimer",
	types = { "poison" },
	baseStats = {
		hp = 80,
		attack = 80,
		defense = 50,
		specialAttack = 40,
		specialDefense = 50,
		speed = 25,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 89, method = "level-up", level = 38 },
	evolutions = { { speciesId = 89, method = "level-up", level = 38 } },
	runtime = { placeholder = false, lookType = 3088, level = 5 },
}
