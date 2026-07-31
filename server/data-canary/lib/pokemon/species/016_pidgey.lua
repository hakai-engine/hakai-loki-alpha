return {
	id = 16,
	name = "Pidgey",
	types = { "normal", "flying" },
	baseStats = {
		hp = 40,
		attack = 45,
		defense = 40,
		specialAttack = 35,
		specialDefense = 35,
		speed = 56,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 50,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 17, method = "level-up", level = 18 },
	evolutions = { { speciesId = 17, method = "level-up", level = 18 } },
	runtime = { placeholder = false, lookType = 3016, level = 5 },
}
