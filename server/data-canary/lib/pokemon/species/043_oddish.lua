return {
	id = 43,
	name = "Oddish",
	types = { "grass", "poison" },
	baseStats = {
		hp = 45,
		attack = 50,
		defense = 55,
		specialAttack = 75,
		specialDefense = 65,
		speed = 30,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 64,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 44, method = "level-up", level = 21 },
	evolutions = { { speciesId = 44, method = "level-up", level = 21 } },
	runtime = { placeholder = false, lookType = 3043, level = 5 },
}
