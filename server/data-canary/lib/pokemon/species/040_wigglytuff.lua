return {
	id = 40,
	name = "Wigglytuff",
	types = { "normal", "fairy" },
	baseStats = {
		hp = 140,
		attack = 70,
		defense = 45,
		specialAttack = 85,
		specialDefense = 50,
		speed = 45,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 50,
	baseExperience = 196,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3040, level = 40 },
}
