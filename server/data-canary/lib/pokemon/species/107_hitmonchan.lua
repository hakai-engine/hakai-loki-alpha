return {
	id = 107,
	name = "Hitmonchan",
	types = { "fighting" },
	baseStats = {
		hp = 50,
		attack = 105,
		defense = 79,
		specialAttack = 35,
		specialDefense = 110,
		speed = 76,
	},
	gender = { male = 1000, female = 0, genderless = 0 },
	catchRate = 45,
	baseExperience = 159,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3107, level = 40 },
}
