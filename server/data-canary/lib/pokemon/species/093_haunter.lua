return {
	id = 93,
	name = "Haunter",
	types = { "ghost", "poison" },
	baseStats = {
		hp = 45,
		attack = 50,
		defense = 45,
		specialAttack = 115,
		specialDefense = 55,
		speed = 95,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 94, method = "trade" },
	evolutions = { { speciesId = 94, method = "trade" } },
	runtime = { placeholder = false, lookType = 3093, level = 20 },
}
