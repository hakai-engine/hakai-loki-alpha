return {
	id = 73,
	name = "Tentacruel",
	types = { "water", "poison" },
	baseStats = {
		hp = 80,
		attack = 70,
		defense = 65,
		specialAttack = 80,
		specialDefense = 120,
		speed = 100,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 180,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3073, level = 40 },
}
