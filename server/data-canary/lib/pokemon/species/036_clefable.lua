return {
	id = 36,
	name = "Clefable",
	types = { "fairy" },
	baseStats = {
		hp = 95,
		attack = 70,
		defense = 73,
		specialAttack = 95,
		specialDefense = 90,
		speed = 60,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 25,
	baseExperience = 217,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3036, level = 40 },
}
