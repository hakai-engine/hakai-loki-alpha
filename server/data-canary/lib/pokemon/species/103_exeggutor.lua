return {
	id = 103,
	name = "Exeggutor",
	types = { "grass", "psychic" },
	baseStats = {
		hp = 95,
		attack = 95,
		defense = 85,
		specialAttack = 125,
		specialDefense = 75,
		speed = 55,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 186,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3103, level = 40 },
}
