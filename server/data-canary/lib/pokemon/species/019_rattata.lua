return {
	id = 19,
	name = "Rattata",
	types = { "normal" },
	baseStats = {
		hp = 30,
		attack = 56,
		defense = 35,
		specialAttack = 25,
		specialDefense = 35,
		speed = 72,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 51,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 20, method = "level-up", level = 20 },
	evolutions = { { speciesId = 20, method = "level-up", level = 20 } },
	runtime = { placeholder = false, lookType = 3019, level = 5 },
}
