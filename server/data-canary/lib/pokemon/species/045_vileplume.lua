return {
	id = 45,
	name = "Vileplume",
	types = { "grass", "poison" },
	baseStats = {
		hp = 75,
		attack = 80,
		defense = 85,
		specialAttack = 110,
		specialDefense = 90,
		speed = 50,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 221,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3045, level = 40 },
}
