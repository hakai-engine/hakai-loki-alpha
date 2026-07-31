return {
	id = 142,
	name = "Aerodactyl",
	types = { "rock", "flying" },
	baseStats = {
		hp = 80,
		attack = 105,
		defense = 65,
		specialAttack = 60,
		specialDefense = 75,
		speed = 130,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 180,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3142, level = 20 },
}
