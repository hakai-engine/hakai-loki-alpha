return {
	id = 60,
	name = "Poliwag",
	types = { "water" },
	baseStats = {
		hp = 40,
		attack = 50,
		defense = 40,
		specialAttack = 40,
		specialDefense = 40,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 61, method = "level-up", level = 25 },
	evolutions = { { speciesId = 61, method = "level-up", level = 25 } },
	runtime = { placeholder = false, lookType = 3060, level = 5 },
}
