return {
	id = 120,
	name = "Staryu",
	types = { "water" },
	baseStats = {
		hp = 30,
		attack = 45,
		defense = 55,
		specialAttack = 70,
		specialDefense = 55,
		speed = 85,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 225,
	baseExperience = 68,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 121, method = "use-item", item = "water-stone" },
	evolutions = { { speciesId = 121, method = "use-item", item = "water-stone" } },
	runtime = { placeholder = false, lookType = 3120, level = 5 },
}
