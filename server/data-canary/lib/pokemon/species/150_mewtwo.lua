return {
	id = 150,
	name = "Mewtwo",
	classification = "legendary",
	types = { "psychic" },
	baseStats = {
		hp = 106,
		attack = 110,
		defense = 90,
		specialAttack = 154,
		specialDefense = 90,
		speed = 130,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 3,
	baseExperience = 306,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3150, level = 50 },
}
