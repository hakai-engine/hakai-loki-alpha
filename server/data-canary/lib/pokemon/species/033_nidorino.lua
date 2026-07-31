return {
	id = 33,
	name = "Nidorino",
	types = { "poison" },
	baseStats = {
		hp = 61,
		attack = 72,
		defense = 57,
		specialAttack = 55,
		specialDefense = 55,
		speed = 65,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 120,
	baseExperience = 128,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 34, method = "use-item", item = "moon-stone" },
	evolutions = { { speciesId = 34, method = "use-item", item = "moon-stone" } },
	runtime = { placeholder = false, lookType = 3033, level = 20 },
}
