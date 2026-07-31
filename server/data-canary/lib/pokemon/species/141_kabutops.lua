return {
	id = 141,
	name = "Kabutops",
	types = { "rock", "water" },
	baseStats = {
		hp = 60,
		attack = 115,
		defense = 105,
		specialAttack = 65,
		specialDefense = 70,
		speed = 80,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 173,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3141, level = 40 },
}
