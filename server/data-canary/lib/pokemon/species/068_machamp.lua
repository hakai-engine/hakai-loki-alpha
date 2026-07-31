return {
	id = 68,
	name = "Machamp",
	types = { "fighting" },
	baseStats = {
		hp = 90,
		attack = 130,
		defense = 80,
		specialAttack = 65,
		specialDefense = 85,
		speed = 55,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 45,
	baseExperience = 227,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = {
		placeholder = false,
		lookType = 3068,
		level = 40,
		speed = 200,
		staticAttackChance = 70,
		targetDistance = 1,
	},
}
