return {
	id = 27,
	name = "Sandshrew",
	types = { "ground" },
	baseStats = {
		hp = 50,
		attack = 75,
		defense = 85,
		specialAttack = 20,
		specialDefense = 30,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 28, method = "level-up", level = 22 },
	evolutions = { { speciesId = 28, method = "level-up", level = 22 } },
	runtime = { placeholder = false, lookType = 3027, level = 5 },
}
