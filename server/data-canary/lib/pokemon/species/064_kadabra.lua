return {
	id = 64,
	name = "Kadabra",
	types = { "psychic" },
	baseStats = {
		hp = 40,
		attack = 35,
		defense = 30,
		specialAttack = 120,
		specialDefense = 70,
		speed = 105,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 100,
	baseExperience = 140,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 65, method = "trade" },
	evolutions = { { speciesId = 65, method = "trade" } },
	runtime = { placeholder = false, lookType = 3064, level = 20 },
}
