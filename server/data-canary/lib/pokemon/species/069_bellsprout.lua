return {
	id = 69,
	name = "Bellsprout",
	types = { "grass", "poison" },
	baseStats = {
		hp = 50,
		attack = 75,
		defense = 35,
		specialAttack = 70,
		specialDefense = 30,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 70, method = "level-up", level = 21 },
	evolutions = { { speciesId = 70, method = "level-up", level = 21 } },
	runtime = { placeholder = false, lookType = 3069, level = 5 },
}
