return {
	id = 97,
	name = "Hypno",
	types = { "psychic" },
	baseStats = {
		hp = 85,
		attack = 73,
		defense = 70,
		specialAttack = 73,
		specialDefense = 115,
		speed = 67,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 169,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3097, level = 40 },
}
