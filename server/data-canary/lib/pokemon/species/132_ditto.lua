return {
	id = 132,
	name = "Ditto",
	types = { "normal" },
	baseStats = {
		hp = 48,
		attack = 48,
		defense = 48,
		specialAttack = 48,
		specialDefense = 48,
		speed = 48,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 35,
	baseExperience = 101,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3132, level = 20 },
}
