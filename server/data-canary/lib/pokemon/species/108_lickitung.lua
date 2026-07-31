return {
	id = 108,
	name = "Lickitung",
	types = { "normal" },
	baseStats = {
		hp = 90,
		attack = 55,
		defense = 75,
		specialAttack = 60,
		specialDefense = 75,
		speed = 30,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 77,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 463, method = "level-up" },
	evolutions = { { speciesId = 463, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3108, level = 5 },
}
