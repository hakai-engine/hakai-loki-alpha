return {
	id = 100,
	name = "Voltorb",
	types = { "electric" },
	baseStats = {
		hp = 40,
		attack = 30,
		defense = 50,
		specialAttack = 55,
		specialDefense = 55,
		speed = 100,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 190,
	baseExperience = 66,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 101, method = "level-up", level = 30 },
	evolutions = { { speciesId = 101, method = "level-up", level = 30 } },
	runtime = { placeholder = false, lookType = 3100, level = 5 },
}
