return {
	id = 15,
	name = "Beedrill",
	types = { "bug", "poison" },
	baseStats = {
		hp = 65,
		attack = 90,
		defense = 40,
		specialAttack = 45,
		specialDefense = 80,
		speed = 75,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 178,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3015, level = 40 },
}
