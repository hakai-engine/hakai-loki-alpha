return {
	id = 148,
	name = "Dragonair",
	types = { "dragon" },
	baseStats = {
		hp = 61,
		attack = 84,
		defense = 65,
		specialAttack = 70,
		specialDefense = 70,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 147,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 149, method = "level-up", level = 55 },
	evolutions = { { speciesId = 149, method = "level-up", level = 55 } },
	runtime = { placeholder = false, lookType = 3148, level = 50 },
}
