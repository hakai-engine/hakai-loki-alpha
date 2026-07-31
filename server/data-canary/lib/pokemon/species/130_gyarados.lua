return {
	id = 130,
	name = "Gyarados",
	types = { "water", "flying" },
	baseStats = {
		hp = 95,
		attack = 125,
		defense = 79,
		specialAttack = 60,
		specialDefense = 100,
		speed = 81,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 189,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3130, level = 40 },
}
