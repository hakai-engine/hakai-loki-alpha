return {
	id = 29,
	name = "Nidoran F",
	types = { "poison" },
	baseStats = {
		hp = 55,
		attack = 47,
		defense = 52,
		specialAttack = 40,
		specialDefense = 40,
		speed = 41,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 235,
	baseExperience = 55,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 30, method = "level-up", level = 16 },
	evolutions = { { speciesId = 30, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3029, level = 5 },
}
