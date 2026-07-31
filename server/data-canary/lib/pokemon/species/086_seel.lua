return {
	id = 86,
	name = "Seel",
	types = { "water" },
	baseStats = {
		hp = 65,
		attack = 45,
		defense = 55,
		specialAttack = 45,
		specialDefense = 70,
		speed = 45,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 87, method = "level-up", level = 34 },
	evolutions = { { speciesId = 87, method = "level-up", level = 34 } },
	runtime = { placeholder = false, lookType = 3086, level = 5 },
}
