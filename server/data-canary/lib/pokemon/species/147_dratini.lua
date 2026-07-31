return {
	id = 147,
	name = "Dratini",
	types = { "dragon" },
	baseStats = {
		hp = 41,
		attack = 64,
		defense = 45,
		specialAttack = 50,
		specialDefense = 50,
		speed = 50,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 148, method = "level-up", level = 30 },
	evolutions = { { speciesId = 148, method = "level-up", level = 30 } },
	runtime = { placeholder = false, lookType = 3147, level = 50 },
}
