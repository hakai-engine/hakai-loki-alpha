return {
	id = 128,
	name = "Tauros",
	types = { "normal" },
	baseStats = {
		hp = 75,
		attack = 100,
		defense = 95,
		specialAttack = 40,
		specialDefense = 70,
		speed = 110,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 45,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3128, level = 20 },
}
