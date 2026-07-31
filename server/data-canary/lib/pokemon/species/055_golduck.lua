return {
	id = 55,
	name = "Golduck",
	types = { "water" },
	baseStats = {
		hp = 80,
		attack = 82,
		defense = 78,
		specialAttack = 95,
		specialDefense = 80,
		speed = 85,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 175,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3055, level = 40 },
}
