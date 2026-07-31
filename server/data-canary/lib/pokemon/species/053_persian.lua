return {
	id = 53,
	name = "Persian",
	types = { "normal" },
	baseStats = {
		hp = 65,
		attack = 70,
		defense = 60,
		specialAttack = 65,
		specialDefense = 65,
		speed = 115,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 154,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3053, level = 40 },
}
