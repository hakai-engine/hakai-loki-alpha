return {
	id = 76,
	name = "Golem",
	types = { "rock", "ground" },
	baseStats = {
		hp = 80,
		attack = 120,
		defense = 130,
		specialAttack = 55,
		specialDefense = 65,
		speed = 45,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 223,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3076, level = 40 },
}
