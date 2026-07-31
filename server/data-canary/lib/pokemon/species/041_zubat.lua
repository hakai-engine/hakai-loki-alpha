return {
	id = 41,
	name = "Zubat",
	types = { "poison", "flying" },
	baseStats = {
		hp = 40,
		attack = 45,
		defense = 35,
		specialAttack = 30,
		specialDefense = 40,
		speed = 55,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 49,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 42, method = "level-up", level = 22 },
	evolutions = { { speciesId = 42, method = "level-up", level = 22 } },
	runtime = { placeholder = false, lookType = 3041, level = 5 },
}
