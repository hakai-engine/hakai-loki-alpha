return {
	id = 111,
	name = "Rhyhorn",
	types = { "ground", "rock" },
	baseStats = {
		hp = 80,
		attack = 85,
		defense = 95,
		specialAttack = 30,
		specialDefense = 30,
		speed = 25,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 69,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 112, method = "level-up", level = 42 },
	evolutions = { { speciesId = 112, method = "level-up", level = 42 } },
	runtime = { placeholder = false, lookType = 3111, level = 5 },
}
