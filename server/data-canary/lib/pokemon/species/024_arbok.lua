return {
	id = 24,
	name = "Arbok",
	types = { "poison" },
	baseStats = {
		hp = 60,
		attack = 95,
		defense = 69,
		specialAttack = 65,
		specialDefense = 79,
		speed = 80,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 157,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3024, level = 40 },
}
