return {
	id = 136,
	name = "Flareon",
	types = { "fire" },
	baseStats = {
		hp = 65,
		attack = 130,
		defense = 60,
		specialAttack = 95,
		specialDefense = 110,
		speed = 65,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 184,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3136, level = 40 },
}
