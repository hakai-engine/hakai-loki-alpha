return {
	id = 49,
	name = "Venomoth",
	types = { "bug", "poison" },
	baseStats = {
		hp = 70,
		attack = 65,
		defense = 60,
		specialAttack = 90,
		specialDefense = 75,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 158,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3049, level = 40 },
}
