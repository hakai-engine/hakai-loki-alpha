return {
	id = 81,
	name = "Magnemite",
	types = { "electric", "steel" },
	baseStats = {
		hp = 25,
		attack = 35,
		defense = 70,
		specialAttack = 95,
		specialDefense = 55,
		speed = 45,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 190,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 82, method = "level-up", level = 30 },
	evolutions = { { speciesId = 82, method = "level-up", level = 30 } },
	runtime = { placeholder = false, lookType = 3081, level = 5 },
}
