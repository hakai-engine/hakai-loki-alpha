return {
	id = 3,
	name = "Venusaur",
	types = { "grass", "poison" },
	baseStats = {
		hp = 80,
		attack = 82,
		defense = 83,
		specialAttack = 100,
		specialDefense = 100,
		speed = 80,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 236,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3003, level = 40 },
}
