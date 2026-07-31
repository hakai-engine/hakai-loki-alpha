return {
	id = 115,
	name = "Kangaskhan",
	types = { "normal" },
	baseStats = {
		hp = 105,
		attack = 95,
		defense = 80,
		specialAttack = 40,
		specialDefense = 80,
		speed = 90,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 45,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3115, level = 20 },
}
