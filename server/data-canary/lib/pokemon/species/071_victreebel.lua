return {
	id = 71,
	name = "Victreebel",
	types = { "grass", "poison" },
	baseStats = {
		hp = 80,
		attack = 105,
		defense = 65,
		specialAttack = 100,
		specialDefense = 70,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 221,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3071, level = 40 },
}
