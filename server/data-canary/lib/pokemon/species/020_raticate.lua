return {
	id = 20,
	name = "Raticate",
	types = { "normal" },
	baseStats = {
		hp = 55,
		attack = 81,
		defense = 60,
		specialAttack = 50,
		specialDefense = 70,
		speed = 97,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 127,
	baseExperience = 145,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3020, level = 40 },
}
