return {
	id = 151,
	name = "Mew",
	classification = "legendary",
	types = { "psychic" },
	baseStats = {
		hp = 100,
		attack = 100,
		defense = 100,
		specialAttack = 100,
		specialDefense = 100,
		speed = 100,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 45,
	baseExperience = 270,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3151, level = 50 },
}
