return {
	id = 32,
	name = "Nidoran M",
	types = { "poison" },
	baseStats = {
		hp = 46,
		attack = 57,
		defense = 40,
		specialAttack = 40,
		specialDefense = 40,
		speed = 50,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 235,
	baseExperience = 55,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 33, method = "level-up", level = 16 },
	evolutions = { { speciesId = 33, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3032, level = 5 },
}
