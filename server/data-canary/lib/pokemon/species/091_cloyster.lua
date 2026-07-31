return {
	id = 91,
	name = "Cloyster",
	types = { "water", "ice" },
	baseStats = {
		hp = 50,
		attack = 95,
		defense = 180,
		specialAttack = 85,
		specialDefense = 45,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 184,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3091, level = 40 },
}
