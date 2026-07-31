return {
	id = 110,
	name = "Weezing",
	types = { "poison" },
	baseStats = {
		hp = 65,
		attack = 90,
		defense = 120,
		specialAttack = 85,
		specialDefense = 70,
		speed = 60,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3110, level = 40 },
}
