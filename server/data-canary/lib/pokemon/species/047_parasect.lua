return {
	id = 47,
	name = "Parasect",
	types = { "bug", "grass" },
	baseStats = {
		hp = 60,
		attack = 95,
		defense = 80,
		specialAttack = 60,
		specialDefense = 80,
		speed = 30,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 142,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3047, level = 40 },
}
