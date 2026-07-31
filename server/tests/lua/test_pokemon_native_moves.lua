-- Verifies the shape handed to Canary's native MonsterType combat parser.
-- Run from the repository root with the bundled LuaJIT.

DATA_DIRECTORY = "data-canary"

DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST = 0, 1, 2, 3
DIRECTION_SOUTHWEST, DIRECTION_SOUTHEAST = 4, 5
DIRECTION_NORTHWEST, DIRECTION_NORTHEAST, DIRECTION_NONE = 6, 7, 8

COMBAT_PHYSICALDAMAGE = 1
COMBAT_ENERGYDAMAGE = 2
COMBAT_EARTHDAMAGE = 3
COMBAT_FIREDAMAGE = 4
COMBAT_LIFEDRAIN = 5
COMBAT_ICEDAMAGE = 6
COMBAT_HOLYDAMAGE = 7
COMBAT_DEATHDAMAGE = 8
COMBAT_NEUTRALDAMAGE = 13

POKEMON_MOVE_CATEGORY_PHYSICAL = 1
POKEMON_MOVE_CATEGORY_SPECIAL = 2
POKEMON_MOVE_CATEGORY_STATUS = 3

CONST_ME_HITAREA = 1
CONST_ME_FIREAREA = 2
CONST_ME_WATERSPLASH = 3
CONST_ME_GREEN_RINGS = 4
CONST_ME_ENERGYHIT = 5
CONST_ME_ICEATTACK = 6
CONST_ME_EXPLOSIONHIT = 7
CONST_ME_HITBYPOISON = 8
CONST_ME_GROUNDSHAKER = 9
CONST_ME_SOUND_WHITE = 10
CONST_ME_MAGIC_BLUE = 11
CONST_ME_MAGIC_GREEN = 12
CONST_ME_BLOCKHIT = 13
CONST_ME_MORTAREA = 14
CONST_ME_MAGIC_RED = 15
CONST_ME_SMALLCLOUDS = 16
CONST_ME_STUN = 17
CONST_ME_HEARTS = 18
CONST_ME_CARNIPHILA = 19

CONST_ANI_LARGEROCK = 1
CONST_ANI_FIRE = 2
CONST_ANI_SMALLICE = 3
CONST_ANI_GREENSTAR = 4
CONST_ANI_ENERGY = 5
CONST_ANI_ICE = 6
CONST_ANI_POISON = 7
CONST_ANI_SMALLSTONE = 8
CONST_ANI_WHIRLWINDSWORD = 9
CONST_ANI_DEATH = 10
CONST_ANI_REDSTAR = 11

BESTY_RACE_KANTO = 25

dofile(DATA_DIRECTORY .. "/lib/pokemon/constants.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/rules.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/combat_config.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/types.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/corpses.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/natures.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/stats.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/species.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/encounter.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/moves.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/monster_factory.lua")

PokemonSpecies.loadCatalog()

local registered = {}
Game = {
	createMonsterType = function(name)
		return {
			register = function(_, monster)
				registered[name] = monster
			end,
		}
	end,
}

local function assertAttack(speciesId, expected)
	local species = assert(PokemonSpecies.get(speciesId))
	PokemonMonsterFactory.register(speciesId)
	local monster = assert(registered[species.name])

	for _, attack in ipairs(monster.attacks) do
		if attack.name == "combat"
			and attack.type == expected.type
			and attack.pokemonType == expected.pokemonType
			and attack.pokemonCategory == expected.pokemonCategory
			and attack.pokemonPower == expected.pokemonPower
			and attack.maxDamage == expected.maxDamage
			and attack.length == expected.length
			and attack.spread == expected.spread
			and attack.radius == expected.radius
			and attack.effect == expected.effect
			and attack.castText == expected.castText
			and (expected.castVisual == nil or (
				attack.castVisual
				and attack.castVisual.north == expected.castVisual.north
				and attack.castVisual.east == expected.castVisual.east
				and attack.castVisual.south == expected.castVisual.south
				and attack.castVisual.west == expected.castVisual.west
				and attack.castVisual.width == expected.castVisual.width
				and attack.castVisual.length == expected.castVisual.length
			))
			and attack.target == false then
			return
		end
	end

	error(string.format("%s did not register the expected native combat for %s", species.name, expected.castText))
end

assertAttack(1, {
	type = COMBAT_NEUTRALDAMAGE,
	pokemonType = 5,
	pokemonCategory = POKEMON_MOVE_CATEGORY_PHYSICAL,
	pokemonPower = 45,
	maxDamage = -45,
	length = 8,
	spread = 3,
	effect = false,
	castText = "Vine Whip!",
	castVisual = {
		north = 372,
		east = 375,
		south = 373,
		west = 374,
		width = 3,
		length = 3,
	},
})

assertAttack(1, {
	type = COMBAT_NEUTRALDAMAGE,
	pokemonType = 5,
	pokemonCategory = POKEMON_MOVE_CATEGORY_SPECIAL,
	pokemonPower = 120,
	maxDamage = -120,
	length = 6,
	spread = 6,
	effect = false,
	castText = "Solar Beam!",
	castVisual = {
		north = 84,
		east = 83,
		south = 82,
		west = 81,
		width = 3,
		length = 6,
	},
})

assertAttack(6, {
	type = COMBAT_NEUTRALDAMAGE,
	pokemonType = 9,
	pokemonCategory = POKEMON_MOVE_CATEGORY_PHYSICAL,
	pokemonPower = 100,
	maxDamage = -100,
	radius = 2,
	effect = false,
	castText = "Earthquake!",
	castVisual = {
		north = 356,
		east = 356,
		south = 356,
		west = 356,
		width = 0,
		length = 0,
	},
})

assertAttack(86, {
	type = COMBAT_NEUTRALDAMAGE,
	pokemonType = 6,
	pokemonCategory = POKEMON_MOVE_CATEGORY_SPECIAL,
	pokemonPower = 65,
	maxDamage = -65,
	length = 6,
	spread = 6,
	effect = CONST_ME_ICEATTACK,
	castText = "Aurora Beam!",
})

print("4 native Pokemon move registrations passed")
