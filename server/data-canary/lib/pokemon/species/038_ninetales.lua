return {
	id = 38,
	name = "Ninetales",
	types = { "fire" },
	baseStats = {
		hp = 73,
		attack = 76,
		defense = 75,
		specialAttack = 81,
		specialDefense = 100,
		speed = 100,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 75,
	baseExperience = 177,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3038, level = 40 },
}
