return {
	id = 25,
	name = "Pikachu",
	types = { "electric" },
	baseStats = {
		hp = 35,
		attack = 55,
		defense = 40,
		specialAttack = 50,
		specialDefense = 50,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 112,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 26, method = "use-item", item = "thunder-stone" },
	evolutions = { { speciesId = 26, method = "use-item", item = "thunder-stone" } },
	runtime = { placeholder = false, lookType = 3025, level = 20 },
}
