return {
	id = 98,
	name = "Krabby",
	types = { "water" },
	baseStats = {
		hp = 30,
		attack = 105,
		defense = 90,
		specialAttack = 25,
		specialDefense = 25,
		speed = 50,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 225,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 99, method = "level-up", level = 28 },
	evolutions = { { speciesId = 99, method = "level-up", level = 28 } },
	runtime = { placeholder = false, lookType = 3098, level = 5 },
}
