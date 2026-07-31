return {
	id = 39,
	name = "Jigglypuff",
	types = { "normal", "fairy" },
	baseStats = {
		hp = 115,
		attack = 45,
		defense = 20,
		specialAttack = 45,
		specialDefense = 25,
		speed = 20,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 170,
	baseExperience = 95,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 40, method = "use-item", item = "moon-stone" },
	evolutions = { { speciesId = 40, method = "use-item", item = "moon-stone" } },
	runtime = { placeholder = false, lookType = 3039, level = 20 },
}
