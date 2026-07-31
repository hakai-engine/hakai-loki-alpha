return {
	id = 87,
	name = "Dewgong",
	types = { "water", "ice" },
	baseStats = {
		hp = 90,
		attack = 70,
		defense = 80,
		specialAttack = 70,
		specialDefense = 95,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 166,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3087, level = 40 },
}
