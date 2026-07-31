return {
	id = 106,
	name = "Hitmonlee",
	types = { "fighting" },
	baseStats = {
		hp = 50,
		attack = 120,
		defense = 53,
		specialAttack = 35,
		specialDefense = 110,
		speed = 87,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 45,
	baseExperience = 159,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3106, level = 40 },
}
