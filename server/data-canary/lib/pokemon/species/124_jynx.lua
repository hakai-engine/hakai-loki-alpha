return {
	id = 124,
	name = "Jynx",
	types = { "ice", "psychic" },
	baseStats = {
		hp = 65,
		attack = 50,
		defense = 35,
		specialAttack = 115,
		specialDefense = 95,
		speed = 95,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 45,
	baseExperience = 159,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3124, level = 40 },
}
