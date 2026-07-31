return {
	id = 34,
	name = "Nidoking",
	types = { "poison", "ground" },
	baseStats = {
		hp = 81,
		attack = 102,
		defense = 77,
		specialAttack = 85,
		specialDefense = 75,
		speed = 85,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 45,
	baseExperience = 227,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3034, level = 40 },
}
