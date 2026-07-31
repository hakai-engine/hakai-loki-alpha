return {
	id = 95,
	name = "Onix",
	types = { "rock", "ground" },
	baseStats = {
		hp = 35,
		attack = 45,
		defense = 160,
		specialAttack = 30,
		specialDefense = 45,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 77,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 208, method = "trade", item = "metal-coat" },
	evolutions = { { speciesId = 208, method = "trade", item = "metal-coat" } },
	runtime = { placeholder = false, lookType = 3095, level = 5 },
}
