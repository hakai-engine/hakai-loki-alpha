return {
	id = 17,
	name = "Pidgeotto",
	types = { "normal", "flying" },
	baseStats = {
		hp = 63,
		attack = 60,
		defense = 55,
		specialAttack = 50,
		specialDefense = 50,
		speed = 71,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 122,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 18, method = "level-up", level = 36 },
	evolutions = { { speciesId = 18, method = "level-up", level = 36 } },
	runtime = { placeholder = false, lookType = 3017, level = 20 },
}
