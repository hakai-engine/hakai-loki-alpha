return {
	id = 48,
	name = "Venonat",
	types = { "bug", "poison" },
	baseStats = {
		hp = 60,
		attack = 55,
		defense = 50,
		specialAttack = 40,
		specialDefense = 55,
		speed = 45,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 61,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 49, method = "level-up", level = 31 },
	evolutions = { { speciesId = 49, method = "level-up", level = 31 } },
	runtime = { placeholder = false, lookType = 3048, level = 5 },
}
