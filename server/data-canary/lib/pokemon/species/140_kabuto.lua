return {
	id = 140,
	name = "Kabuto",
	types = { "rock", "water" },
	baseStats = {
		hp = 30,
		attack = 80,
		defense = 90,
		specialAttack = 55,
		specialDefense = 45,
		speed = 55,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 71,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 141, method = "level-up", level = 40 },
	evolutions = { { speciesId = 141, method = "level-up", level = 40 } },
	runtime = { placeholder = false, lookType = 3140, level = 5 },
}
