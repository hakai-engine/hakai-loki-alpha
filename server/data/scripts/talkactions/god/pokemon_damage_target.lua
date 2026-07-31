PokemonDamageTarget = PokemonDamageTarget or {}

local DEFAULTS = {
	type1 = "normal",
	type2 = nil,
	defense = 120,
	specialDefense = 120,
	health = 100000000,
	level = 50,
}

local MAX_DEFENSE = 1000000
local MAX_HEALTH = 2000000000
local USAGE = "/poketarget [type|type1/type2] [defense] [specialDefense] [health]"

local typeAliases = {
	normal = "normal",
	fire = "fire",
	fogo = "fire",
	water = "water",
	agua = "water",
	electric = "electric",
	eletrico = "electric",
	grass = "grass",
	planta = "grass",
	ice = "ice",
	gelo = "ice",
	fighting = "fighting",
	lutador = "fighting",
	poison = "poison",
	veneno = "poison",
	ground = "ground",
	terra = "ground",
	flying = "flying",
	voador = "flying",
	psychic = "psychic",
	psiquico = "psychic",
	bug = "bug",
	inseto = "bug",
	rock = "rock",
	pedra = "rock",
	ghost = "ghost",
	fantasma = "ghost",
	dragon = "dragon",
	dragao = "dragon",
	dark = "dark",
	sombrio = "dark",
	steel = "steel",
	aco = "steel",
	fairy = "fairy",
	fada = "fairy",
}

local function parseInteger(value, label, minimum, maximum)
	local number = tonumber(value)
	if not number or number % 1 ~= 0 or number < minimum or number > maximum then
		return nil, string.format("%s must be an integer from %d to %d.", label, minimum, maximum)
	end
	return number
end

local function normalizeType(value)
	return typeAliases[value:lower()]
end

function PokemonDamageTarget.parse(param)
	local values = {}
	for value in param:gsub(",", " "):gmatch("%S+") do
		values[#values + 1] = value
	end

	if values[1] and values[1]:lower() == "help" then
		return nil, USAGE
	end
	if #values > 4 then
		return nil, USAGE
	end

	local config = {
		type1 = DEFAULTS.type1,
		type2 = DEFAULTS.type2,
		defense = DEFAULTS.defense,
		specialDefense = DEFAULTS.specialDefense,
		health = DEFAULTS.health,
		level = DEFAULTS.level,
	}

	if values[1] then
		local rawType1, rawType2 = values[1]:match("^([^/+]+)[/+]?([^/+]*)$")
		config.type1 = rawType1 and normalizeType(rawType1) or nil
		config.type2 = rawType2 ~= "" and normalizeType(rawType2) or nil
		if not config.type1 or (rawType2 ~= "" and not config.type2) then
			return nil, "Unknown Pokemon type. Valid types: normal, fire, water, electric, grass, ice, fighting, poison, ground, flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy."
		end
		if config.type2 == config.type1 then
			return nil, "Primary and secondary types must be different."
		end
	end

	if values[2] then
		local errorMessage
		config.defense, errorMessage = parseInteger(values[2], "Defense", 0, MAX_DEFENSE)
		if not config.defense then
			return nil, errorMessage
		end
	end
	if values[3] then
		local errorMessage
		config.specialDefense, errorMessage = parseInteger(values[3], "Special Defense", 0, MAX_DEFENSE)
		if not config.specialDefense then
			return nil, errorMessage
		end
	end
	if values[4] then
		local errorMessage
		config.health, errorMessage = parseInteger(values[4], "Health", 1, MAX_HEALTH)
		if not config.health then
			return nil, errorMessage
		end
	end

	return config
end

function PokemonDamageTarget.spawn(player, config)
	local position = player:getPosition()
	position:getNextPosition(player:getDirection(), 1)

	local target = Game.createMonster("Training Stake", position, true, true)
	if not target then
		return nil, "There is not enough room to create the Pokemon damage target."
	end

	local configured = target:setPokemonCombatProfile(
		config.level,
		PokemonTypes.id(config.type1),
		config.type2 and PokemonTypes.id(config.type2) or 0,
		1,
		config.defense,
		1,
		config.specialDefense,
		1,
		1.0
	)
	if not configured then
		target:remove()
		return nil, "Could not configure the Pokemon combat profile."
	end

	target:setMaxHealth(config.health)
	local healthDifference = config.health - target:getHealth()
	if healthDifference ~= 0 then
		target:addHealth(healthDifference)
	end
	target:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	return target
end

function PokemonDamageTarget.spawnFromCommand(player, param)
	local config, parseError = PokemonDamageTarget.parse(param)
	if not config then
		return nil, parseError
	end

	local target, spawnError = PokemonDamageTarget.spawn(player, config)
	if not target then
		return nil, spawnError
	end
	return target, config
end

local createPokemonDamageTarget = TalkAction("/poketarget")

function createPokemonDamageTarget.onSay(player, words, param)
	logCommand(player, words, param)

	local target, result = PokemonDamageTarget.spawnFromCommand(player, param)
	if not target then
		player:sendCancelMessage(result .. " Usage: " .. USAGE)
		return true
	end

	local typeLabel = result.type2 and (result.type1 .. "/" .. result.type2) or result.type1
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
		"Pokemon damage target created: type=%s, Defense=%d, Special Defense=%d, HP=%d.",
		typeLabel,
		result.defense,
		result.specialDefense,
		result.health
	))
	return true
end

createPokemonDamageTarget:separator(" ")
createPokemonDamageTarget:groupType("god")
createPokemonDamageTarget:register()
