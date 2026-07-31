return {
	id = 121,
	name = "Starmie",
	types = { "water", "psychic" },
	baseStats = {
		hp = 60,
		attack = 75,
		defense = 85,
		specialAttack = 100,
		specialDefense = 85,
		speed = 115,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 60,
	baseExperience = 182,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3121, level = 40 },
}
