return {
	id = 89,
	name = "Muk",
	types = { "poison" },
	baseStats = {
		hp = 105,
		attack = 105,
		defense = 75,
		specialAttack = 65,
		specialDefense = 100,
		speed = 50,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 175,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3089, level = 40 },
}
