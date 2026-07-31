return {
	id = 80,
	name = "Slowbro",
	types = { "water", "psychic" },
	baseStats = {
		hp = 95,
		attack = 75,
		defense = 110,
		specialAttack = 100,
		specialDefense = 80,
		speed = 30,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3080, level = 40 },
}
