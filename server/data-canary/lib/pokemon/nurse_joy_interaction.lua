NurseJoyInteraction = {
	OPCODE = 203,
	PROTOCOL_VERSION = 1,
	COOLDOWN_SECONDS = 3,
	OUTFIT_ID = 4209,
}

local nextInteractionAt = {}
local interactionInProgress = {}

local function feedbackPayload(total)
	return string.format(
		'{"version":%d,"action":"nurse_joy.healed","data":{"message":"Seus Pokémon estão curados. Volte sempre!","lookType":%d,"duration":3500,"total":%d}}',
		NurseJoyInteraction.PROTOCOL_VERSION,
		NurseJoyInteraction.OUTFIT_ID,
		total
	)
end

function NurseJoyInteraction.handleRequest(player, buffer)
	if type(buffer) ~= "string" or #buffer > 160 then
		return false
	end

	local version = tonumber(buffer:match('"version"%s*:%s*(%d+)'))
	local action = buffer:match('"action"%s*:%s*"([%w%._-]+)"')
	local npcId = tonumber(buffer:match('"npcId"%s*:%s*(%d+)'))
	if version ~= NurseJoyInteraction.PROTOCOL_VERSION or action ~= "nurse_joy.interact" or not npcId then
		return false
	end

	local npc = Npc(npcId)
	if not npc or npc:getName():lower() ~= "nurse joy" then
		return false
	end

	local playerPosition = player:getPosition()
	local npcPosition = npc:getPosition()
	if playerPosition.z ~= npcPosition.z then
		return false
	end
	local distance = math.max(
		math.abs(playerPosition.x - npcPosition.x),
		math.abs(playerPosition.y - npcPosition.y)
	)
	if distance > 3 then
		return false
	end

	return NurseJoyInteraction.interact(player)
end

function NurseJoyInteraction.interact(player)
	if not player then
		return false, "invalid-player"
	end

	local playerId = player:getId()
	local now = os.time()
	if interactionInProgress[playerId] or now < (nextInteractionAt[playerId] or 0) then
		return false, "cooldown"
	end

	interactionInProgress[playerId] = true
	nextInteractionAt[playerId] = now + NurseJoyInteraction.COOLDOWN_SECONDS

	local callOk, restored, _, total, reason = pcall(PokemonHealing.restore, player)
	interactionInProgress[playerId] = nil

	if not callOk then
		logger.error("[NurseJoyInteraction] Failed to heal player {}: {}", player:getName(), restored)
		return false, "service-error"
	end
	if not restored then
		logger.warn("[NurseJoyInteraction] Healing rejected for player {}: {}", player:getName(), reason or "unknown")
		return false, reason or "restore-failed"
	end

	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendExtendedOpcode(NurseJoyInteraction.OPCODE, feedbackPayload(total or 0))
	return true
end
