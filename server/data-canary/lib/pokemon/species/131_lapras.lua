return {
	id = 131,
	name = "Lapras",
	types = { "water", "ice" },
	baseStats = {
		hp = 130,
		attack = 85,
		defense = 80,
		specialAttack = 85,
		specialDefense = 95,
		speed = 60,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 187,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3131, level = 20 },
}
