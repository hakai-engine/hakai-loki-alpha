local internalNpcName = "Nurse Joy"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName
npcConfig.health = 100
npcConfig.maxHealth = 100
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 0
npcConfig.outfit = {
	lookType = 4209, -- Nurse Joy imported from the supplied 2730/2731 sheets
}
npcConfig.flags = { floorchange = false }

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

local function onInstantInteraction(npc, creature, message)
	if type(message) ~= "string" then
		return false
	end

	local normalized = message:lower()
	if normalized ~= "hi" and normalized ~= "hello" and normalized ~= "oi" then
		return false
	end

	local player = Player(creature)
	if not player then
		return false
	end

	NurseJoyInteraction.interact(player)
	return true
end

npcType.onThink = function(npc, interval) npcHandler:onThink(npc, interval) end
npcType.onAppear = function(npc, creature) npcHandler:onAppear(npc, creature) end
npcType.onDisappear = function(npc, creature) npcHandler:onDisappear(npc, creature) end
npcType.onMove = function(npc, creature, fromPosition, toPosition) npcHandler:onMove(npc, creature, fromPosition, toPosition) end
npcType.onSay = function(npc, creature, type, message)
	-- Nurse Joy is an instant-service NPC. Do not forward the greeting to
	-- NpcHandler, because that path opens the generic Canary dialog window.
	onInstantInteraction(npc, creature, message)
end
npcType.onCloseChannel = function(npc, creature) npcHandler:onCloseChannel(npc, creature) end

npcType:register(npcConfig)
