return {
	id = 94,
	name = "Gengar",
	types = { "ghost", "poison" },
	baseStats = {
		hp = 60,
		attack = 65,
		defense = 60,
		specialAttack = 130,
		specialDefense = 75,
		speed = 110,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 225,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3094, level = 40 },
}
