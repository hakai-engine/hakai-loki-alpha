return {
	id = 135,
	name = "Jolteon",
	types = { "electric" },
	baseStats = {
		hp = 65,
		attack = 65,
		defense = 60,
		specialAttack = 110,
		specialDefense = 95,
		speed = 130,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 184,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3135, level = 40 },
}
