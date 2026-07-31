return {
	id = 114,
	name = "Tangela",
	types = { "grass" },
	baseStats = {
		hp = 65,
		attack = 55,
		defense = 115,
		specialAttack = 100,
		specialDefense = 40,
		speed = 60,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 87,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 465, method = "level-up" },
	evolutions = { { speciesId = 465, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3114, level = 5 },
}
