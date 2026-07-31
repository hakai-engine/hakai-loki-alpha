return {
	id = 62,
	name = "Poliwrath",
	types = { "water", "fighting" },
	baseStats = {
		hp = 90,
		attack = 95,
		defense = 95,
		specialAttack = 70,
		specialDefense = 90,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 230,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3062, level = 40 },
}
