return {
	id = 65,
	name = "Alakazam",
	types = { "psychic" },
	baseStats = {
		hp = 55,
		attack = 50,
		defense = 45,
		specialAttack = 135,
		specialDefense = 95,
		speed = 120,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 50,
	baseExperience = 225,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3065, level = 40 },
}
