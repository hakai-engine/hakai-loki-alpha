return {
	id = 6,
	name = "Charizard",
	types = { "fire", "flying" },
	baseStats = {
		hp = 78,
		attack = 84,
		defense = 78,
		specialAttack = 109,
		specialDefense = 85,
		speed = 100,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 240,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3006, level = 40 },
}
