return {
	id = 146,
	name = "Moltres",
	classification = "legendary",
	types = { "fire", "flying" },
	baseStats = {
		hp = 90,
		attack = 100,
		defense = 90,
		specialAttack = 125,
		specialDefense = 85,
		speed = 90,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 3,
	baseExperience = 261,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3146, level = 50 },
}
