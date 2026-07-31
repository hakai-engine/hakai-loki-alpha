return {
	id = 79,
	name = "Slowpoke",
	types = { "water", "psychic" },
	baseStats = {
		hp = 90,
		attack = 65,
		defense = 65,
		specialAttack = 40,
		specialDefense = 40,
		speed = 15,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 63,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 80, method = "level-up", level = 37 },
	evolutions = { { speciesId = 80, method = "level-up", level = 37 }, { speciesId = 199, method = "trade", item = "kings-rock" } },
	runtime = { placeholder = false, lookType = 3079, level = 5 },
}
