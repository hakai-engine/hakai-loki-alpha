return {
	id = 9,
	name = "Blastoise",
	types = { "water" },
	baseStats = {
		hp = 79,
		attack = 83,
		defense = 100,
		specialAttack = 85,
		specialDefense = 105,
		speed = 78,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 239,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3009, level = 40 },
}
