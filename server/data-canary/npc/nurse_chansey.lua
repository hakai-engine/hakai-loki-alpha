local internalNpcName = "Nurse Chansey"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 250
npcConfig.maxHealth = 250
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 0
npcConfig.outfit = {
	lookType = 3113, -- Chansey, Kanto #113
}
npcConfig.flags = { floorchange = false }
npcConfig.voices = {
	interval = 15000,
	chance = 20,
	{ text = "Chansey!" },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

local function healPlayer(npc, creature)
	local player = Player(creature)
	if not player then
		return false
	end

	local restored, _, total = PokemonHealing.restore(player)
	if restored then
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		return true, string.format("Chansey! Your %d Pokemon are fully healed.", total)
	end
	return false, "Chansey could not access your Pokemon records. Please try again."
end

local function greetCallback(npc, creature)
	local restored, message = healPlayer(npc, creature)
	npcHandler:setMessage(MESSAGE_GREET, restored and ("Welcome, |PLAYERNAME|. " .. message) or message)
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "heal") or MsgContains(message, "cura") or MsgContains(message, "pokemon") then
		local _, response = healPlayer(npc, creature)
		npcHandler:say(response, npc, creature)
	end
	return true
end

npcType.onThink = function(npc, interval) npcHandler:onThink(npc, interval) end
npcType.onAppear = function(npc, creature) npcHandler:onAppear(npc, creature) end
npcType.onDisappear = function(npc, creature) npcHandler:onDisappear(npc, creature) end
npcType.onMove = function(npc, creature, fromPosition, toPosition) npcHandler:onMove(npc, creature, fromPosition, toPosition) end
npcType.onSay = function(npc, creature, type, message) npcHandler:onSay(npc, creature, type, message) end
npcType.onCloseChannel = function(npc, creature) npcHandler:onCloseChannel(npc, creature) end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)
npcType:register(npcConfig)
