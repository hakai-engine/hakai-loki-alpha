return {
	id = 145,
	name = "Zapdos",
	classification = "legendary",
	types = { "electric", "flying" },
	baseStats = {
		hp = 90,
		attack = 90,
		defense = 85,
		specialAttack = 125,
		specialDefense = 90,
		speed = 100,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 3,
	baseExperience = 261,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3145, level = 50 },
}
