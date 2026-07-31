return {
	id = 31,
	name = "Nidoqueen",
	types = { "poison", "ground" },
	baseStats = {
		hp = 90,
		attack = 92,
		defense = 87,
		specialAttack = 75,
		specialDefense = 85,
		speed = 76,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 45,
	baseExperience = 227,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3031, level = 40 },
}
