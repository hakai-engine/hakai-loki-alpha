return {
	id = 126,
	name = "Magmar",
	types = { "fire" },
	baseStats = {
		hp = 65,
		attack = 95,
		defense = 57,
		specialAttack = 100,
		specialDefense = 85,
		speed = 93,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 45,
	baseExperience = 173,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 467, method = "trade", item = "magmarizer" },
	evolutions = { { speciesId = 467, method = "trade", item = "magmarizer" } },
	runtime = { placeholder = false, lookType = 3126, level = 20 },
}
