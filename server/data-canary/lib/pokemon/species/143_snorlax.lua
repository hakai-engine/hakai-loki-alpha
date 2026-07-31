return {
	id = 143,
	name = "Snorlax",
	types = { "normal" },
	baseStats = {
		hp = 160,
		attack = 110,
		defense = 65,
		specialAttack = 65,
		specialDefense = 110,
		speed = 30,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 25,
	baseExperience = 189,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3143, level = 40 },
}
