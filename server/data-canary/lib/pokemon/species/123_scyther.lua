return {
	id = 123,
	name = "Scyther",
	types = { "bug", "flying" },
	baseStats = {
		hp = 70,
		attack = 110,
		defense = 80,
		specialAttack = 55,
		specialDefense = 80,
		speed = 105,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 100,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 212, method = "trade", item = "metal-coat" },
	evolutions = { { speciesId = 212, method = "trade", item = "metal-coat" }, { speciesId = 900, method = "use-item", item = "black-augurite" } },
	runtime = { placeholder = false, lookType = 3123, level = 5 },
}
