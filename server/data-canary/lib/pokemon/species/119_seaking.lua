return {
	id = 119,
	name = "Seaking",
	types = { "water" },
	baseStats = {
		hp = 80,
		attack = 92,
		defense = 65,
		specialAttack = 65,
		specialDefense = 80,
		speed = 68,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 158,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3119, level = 40 },
}
