return {
	id = 26,
	name = "Raichu",
	types = { "electric" },
	baseStats = {
		hp = 60,
		attack = 90,
		defense = 55,
		specialAttack = 90,
		specialDefense = 80,
		speed = 110,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 218,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3026, level = 40 },
}
