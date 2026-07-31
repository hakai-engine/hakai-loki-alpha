return {
	id = 83,
	name = "Farfetchd",
	types = { "normal", "flying" },
	baseStats = {
		hp = 52,
		attack = 90,
		defense = 55,
		specialAttack = 58,
		specialDefense = 62,
		speed = 60,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 132,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 865, method = "three-critical-hits" },
	evolutions = { { speciesId = 865, method = "three-critical-hits" } },
	runtime = { placeholder = false, lookType = 3083, level = 5 },
}
