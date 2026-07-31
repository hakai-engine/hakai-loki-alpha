return {
	id = 82,
	name = "Magneton",
	types = { "electric", "steel" },
	baseStats = {
		hp = 50,
		attack = 60,
		defense = 95,
		specialAttack = 120,
		specialDefense = 70,
		speed = 70,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 60,
	baseExperience = 163,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 462, method = "level-up" },
	evolutions = { { speciesId = 462, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3082, level = 20 },
}
