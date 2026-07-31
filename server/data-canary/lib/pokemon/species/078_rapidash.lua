return {
	id = 78,
	name = "Rapidash",
	types = { "fire" },
	baseStats = {
		hp = 65,
		attack = 100,
		defense = 70,
		specialAttack = 80,
		specialDefense = 80,
		speed = 105,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 175,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3078, level = 40 },
}
