return {
	id = 77,
	name = "Ponyta",
	types = { "fire" },
	baseStats = {
		hp = 50,
		attack = 85,
		defense = 55,
		specialAttack = 65,
		specialDefense = 65,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 82,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 78, method = "level-up", level = 40 },
	evolutions = { { speciesId = 78, method = "level-up", level = 40 } },
	runtime = { placeholder = false, lookType = 3077, level = 5 },
}
