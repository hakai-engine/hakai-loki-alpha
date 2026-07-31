return {
	id = 138,
	name = "Omanyte",
	types = { "rock", "water" },
	baseStats = {
		hp = 35,
		attack = 40,
		defense = 100,
		specialAttack = 90,
		specialDefense = 55,
		speed = 35,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 71,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 139, method = "level-up", level = 40 },
	evolutions = { { speciesId = 139, method = "level-up", level = 40 } },
	runtime = { placeholder = false, lookType = 3138, level = 5 },
}
