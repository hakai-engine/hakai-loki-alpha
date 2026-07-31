return {
	id = 74,
	name = "Geodude",
	types = { "rock", "ground" },
	baseStats = {
		hp = 40,
		attack = 80,
		defense = 100,
		specialAttack = 30,
		specialDefense = 30,
		speed = 20,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 75, method = "level-up", level = 25 },
	evolutions = { { speciesId = 75, method = "level-up", level = 25 } },
	runtime = { placeholder = false, lookType = 3074, level = 5 },
}
