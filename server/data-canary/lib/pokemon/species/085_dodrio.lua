return {
	id = 85,
	name = "Dodrio",
	types = { "normal", "flying" },
	baseStats = {
		hp = 60,
		attack = 110,
		defense = 70,
		specialAttack = 60,
		specialDefense = 60,
		speed = 110,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 165,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3085, level = 40 },
}
