local internalNpcName = "Professor Oak"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 100
npcConfig.maxHealth = 100
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1
npcConfig.outfit = {
	lookType = 128,
	lookHead = 57,
	lookBody = 68,
	lookLegs = 76,
	lookFeet = 94,
	lookAddons = 0,
}
npcConfig.flags = {
	floorchange = false,
}
npcConfig.voices = {
	interval = 15000,
	chance = 20,
	{ text = "Every Pokemon journey begins with a choice!" },
}
npcConfig.shop = {
	{ itemName = "Hakai Poke Ball", clientId = 54267, buy = 100 },
	{ itemName = "Hakai Great Ball", clientId = 54420, buy = 300 },
	{ itemName = "Hakai Super Ball", clientId = 54422, buy = 600 },
	{ itemName = "Hakai Ultra Ball", clientId = 54424, buy = 1200 },
}

local starters = {
	bulbasaur = { speciesId = 1, name = "Bulbasaur" },
	charmander = { speciesId = 4, name = "Charmander" },
	squirtle = { speciesId = 7, name = "Squirtle" },
}
local pendingChoice = {}
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval) npcHandler:onThink(npc, interval) end
npcType.onAppear = function(npc, creature) npcHandler:onAppear(npc, creature) end
npcType.onDisappear = function(npc, creature) npcHandler:onDisappear(npc, creature) end
npcType.onMove = function(npc, creature, fromPosition, toPosition) npcHandler:onMove(npc, creature, fromPosition, toPosition) end
npcType.onSay = function(npc, creature, type, message) npcHandler:onSay(npc, creature, type, message) end
npcType.onCloseChannel = function(npc, creature)
	pendingChoice[creature:getId()] = nil
	npcHandler:onCloseChannel(npc, creature)
end

local function greetCallback(npc, creature)
	local player = Player(creature)
	pendingChoice[player:getId()] = nil
	if player:getVocation():getId() ~= VOCATION.ID.TRAINER then
		npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|. I entrust starter Pokemon only to registered Trainers.")
	elseif PokemonRepository.hasStarterChoice(player:getGuid()) then
		npcHandler:setMessage(MESSAGE_GREET, "Welcome back, |PLAYERNAME|. Take good care of the Pokemon you chose.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "Welcome, |PLAYERNAME|! Choose your first Pokemon: {Bulbasaur}, {Charmander}, or {Squirtle}.")
	end
	return true
end

local function deliverStarter(npc, player, starter)
	if PokemonRepository.hasStarterChoice(player:getGuid()) then
		npcHandler:say("You have already chosen your first Pokemon.", npc, player)
		return false
	end

	local hasSpace, _, capacity = PokemonCaptureBag.hasSpace(player:getGuid())
	if not hasSpace then
		npcHandler:say(string.format("Your Capture Bag is full (%d/%d).", capacity, capacity), npc, player)
		return false
	end

	local encounter = PokemonEncounter.create(starter.speciesId, 5)
	local instance, reason = PokemonRepository.createStarter(encounter, player:getGuid(), 54268)
	if not instance then
		logger.error("[ProfessorOak] Starter persistence failed for {}: {}", player:getName(), reason)
		npcHandler:say("Something went wrong. Your choice was not consumed; please try again.", npc, player)
		return false
	end
	local recorded, recordReason = PokemonRepository.recordStarterChoice(player:getGuid(), instance.instanceId, starter.speciesId)
	if not recorded then
		PokemonRepository.deleteUnclaimedStarter(instance.instanceId, player:getGuid())
		logger.error("[ProfessorOak] Starter choice failed for {}: {}", player:getName(), recordReason)
		npcHandler:say("Your choice could not be recorded. No starter was consumed; please try again.", npc, player)
		return false
	end

	npcHandler:say(string.format("Excellent choice! %s is in Capture Bag slot %d.", starter.name, instance.locationSlot), npc, player)
	player:sendTextMessage(MESSAGE_GAME_HIGHLIGHT, string.format("%s joined your team!", starter.name))
	if PokemonRosterProtocol then
		PokemonRosterProtocol.snapshot(player, "bag", string.format("%s entered Capture Bag slot %d.", starter.name, instance.locationSlot), true)
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()
	if not npcHandler:checkInteraction(npc, creature) then return false end

	if player:getVocation():getId() ~= VOCATION.ID.TRAINER then
		npcHandler:say("Become a registered Trainer before choosing a starter Pokemon.", npc, creature)
		return true
	end
	if PokemonRepository.hasStarterChoice(player:getGuid()) then
		npcHandler:say("You have already chosen your first Pokemon.", npc, creature)
		return true
	end

	if MsgContains(message, "yes") and pendingChoice[playerId] then
		local starter = pendingChoice[playerId]
		pendingChoice[playerId] = nil
		deliverStarter(npc, player, starter)
		return true
	end
	if MsgContains(message, "no") and pendingChoice[playerId] then
		pendingChoice[playerId] = nil
		npcHandler:say("Then choose carefully: {Bulbasaur}, {Charmander}, or {Squirtle}.", npc, creature)
		return true
	end

	for keyword, starter in pairs(starters) do
		if MsgContains(message, keyword) then
			pendingChoice[playerId] = starter
			npcHandler:say(string.format("Do you choose %s as your first Pokemon?", starter.name), npc, creature)
			return true
		end
	end

	if MsgContains(message, "starter") or MsgContains(message, "pokemon") then
		npcHandler:say("You may choose {Bulbasaur}, {Charmander}, or {Squirtle}.", npc, creature)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)
npcType:register(npcConfig)
