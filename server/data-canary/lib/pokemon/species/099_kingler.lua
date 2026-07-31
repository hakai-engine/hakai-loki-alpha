return {
	id = 99,
	name = "Kingler",
	types = { "water" },
	baseStats = {
		hp = 55,
		attack = 130,
		defense = 115,
		specialAttack = 50,
		specialDefense = 50,
		speed = 75,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 166,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3099, level = 40 },
}
