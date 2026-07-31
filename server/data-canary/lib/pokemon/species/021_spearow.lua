return {
	id = 21,
	name = "Spearow",
	types = { "normal", "flying" },
	baseStats = {
		hp = 40,
		attack = 60,
		defense = 30,
		specialAttack = 31,
		specialDefense = 31,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 52,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 22, method = "level-up", level = 20 },
	evolutions = { { speciesId = 22, method = "level-up", level = 20 } },
	runtime = { placeholder = false, lookType = 3021, level = 5 },
}
