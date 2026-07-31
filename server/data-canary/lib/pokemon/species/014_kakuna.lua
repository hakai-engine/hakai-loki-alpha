return {
	id = 14,
	name = "Kakuna",
	types = { "bug", "poison" },
	baseStats = {
		hp = 45,
		attack = 25,
		defense = 50,
		specialAttack = 25,
		specialDefense = 25,
		speed = 35,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 72,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 15, method = "level-up", level = 10 },
	evolutions = { { speciesId = 15, method = "level-up", level = 10 } },
	runtime = { placeholder = false, lookType = 3014, level = 20 },
}
