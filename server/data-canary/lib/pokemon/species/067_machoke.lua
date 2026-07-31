return {
	id = 67,
	name = "Machoke",
	types = { "fighting" },
	baseStats = {
		hp = 80,
		attack = 100,
		defense = 70,
		specialAttack = 50,
		specialDefense = 60,
		speed = 45,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 90,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 68, method = "trade" },
	evolutions = { { speciesId = 68, method = "trade" } },
	runtime = { placeholder = false, lookType = 3067, level = 20 },
}
