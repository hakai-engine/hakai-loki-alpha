return {
	id = 50,
	name = "Diglett",
	types = { "ground" },
	baseStats = {
		hp = 10,
		attack = 55,
		defense = 25,
		specialAttack = 35,
		specialDefense = 45,
		speed = 95,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 53,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 51, method = "level-up", level = 26 },
	evolutions = { { speciesId = 51, method = "level-up", level = 26 } },
	runtime = { placeholder = false, lookType = 3050, level = 5 },
}
