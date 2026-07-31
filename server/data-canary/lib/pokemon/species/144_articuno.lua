return {
	id = 144,
	name = "Articuno",
	classification = "legendary",
	types = { "ice", "flying" },
	baseStats = {
		hp = 90,
		attack = 85,
		defense = 100,
		specialAttack = 95,
		specialDefense = 125,
		speed = 85,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 3,
	baseExperience = 261,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3144, level = 50 },
}
