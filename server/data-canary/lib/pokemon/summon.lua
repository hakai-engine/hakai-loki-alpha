PokemonSummon = { active = {} }

local function key(player) return player:getGuid() end
local offsets = {{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}

function PokemonSummon.get(player) return PokemonSummon.active[key(player)] end

function PokemonSummon.getByCreature(creatureId)
    creatureId = tonumber(creatureId)
    if not creatureId then return nil end
    for _, active in pairs(PokemonSummon.active) do
        if active.creatureId == creatureId then return active end
    end
    return nil
end

-- Reflect a persisted level/evolution update onto an already released summon.
-- The database remains authoritative; the Monster is only its live projection.
function PokemonSummon.refreshActiveInstance(player, instance, previousSpeciesId)
    local active = PokemonSummon.get(player)
    if not active or tostring(active.instanceId) ~= tostring(instance.instanceId) then
        return false
    end
    local monster = Monster(active.creatureId)
    if not monster then return false end
    if previousSpeciesId and previousSpeciesId ~= instance.speciesId then
        local species = PokemonSpecies.get(instance.speciesId)
        if not monster:setType(species.name, false) then
            logger.error("[PokemonSummon] Failed to change active instance {} to {}.", instance.instanceId, species.name)
            return false
        end
    end
    PokemonEncounter.active[monster:getId()] = instance
    PokemonEncounter.applyRuntimeCombatProfile(monster, instance)
    monster:setMaxHealth(math.max(instance.maxHp, 1))
    local healthDifference = instance.currentHp - monster:getHealth()
    if healthDifference ~= 0 then monster:addHealth(healthDifference) end
    active.instance = instance
    return true
end

local function persistVitals(active, monster, fainted)
    if not active or not active.instance then return true end
    local instance = active.instance
    if monster then
        instance.maxHp = math.max(monster:getMaxHealth(), 1)
        instance.currentHp = math.max(math.min(monster:getHealth(), instance.maxHp), 0)
    end
    if fainted or instance.currentHp <= 0 then
        instance.currentHp = 0
        instance.state = "fainted"
    else
        instance.state = "ready"
    end
    local updated, reason = PokemonRepository.updateVitals(instance)
    if not updated then
        logger.error("[PokemonSummon] Failed to persist Pokemon instance {} vitals: {}", instance.instanceId, reason or "database update failed")
        return false
    end
    return true
end

function PokemonSummon.releaseByCreature(creatureId)
    for playerGuid,active in pairs(PokemonSummon.active) do
        if active.creatureId==creatureId then
            local monster = Monster(creatureId)
            persistVitals(active, monster, not monster or monster:getHealth() <= 0)
            PokemonSummon.active[playerGuid]=nil
            local player = active.playerId and Player(active.playerId) or nil
            if player and PokemonTargetPolicy then PokemonTargetPolicy.onSummonDismissed(player) end
            return active
        end
    end
    return nil
end

function PokemonSummon.dismiss(player)
	local active = PokemonSummon.get(player)
	if not active then return true end
	local monster = Monster(active.creatureId)
	if not persistVitals(active, monster, false) then
		return false, "Could not save this Pokemon before recall."
	end
    -- Clear first so the onDisappear hook cannot persist the same summon twice.
    PokemonSummon.active[key(player)] = nil
    if monster then monster:remove() end
    if PokemonTargetPolicy then PokemonTargetPolicy.onSummonDismissed(player) end
    return true
end

local function findActiveOwner(instanceId)
    for playerGuid, active in pairs(PokemonSummon.active) do
        if active.instanceId == instanceId then return playerGuid end
    end
    return nil
end

local function isHeldBy(player, ball)
    local topParent = ball:getTopParent()
    return topParent and topParent:isPlayer() and topParent:getGuid() == player:getGuid()
end

local function loadOrTransfer(player, ball, instanceId)
    local playerGuid = player:getGuid()
    local storedOwnerGuid = tonumber(ball:getCustomAttribute("hakai.pokemon.ownerGuid"))
    if not storedOwnerGuid or storedOwnerGuid <= 0 then
        return nil, "This Poke Ball has no valid owner identity."
    end

    local instance = PokemonRepository.load(instanceId, playerGuid)
    if instance then return instance end

    if not isHeldBy(player, ball) then
        return nil, "Pick up this Poke Ball before claiming its Pokemon."
    end
    if findActiveOwner(instanceId) then
        return nil, "This Pokemon is currently outside its Poke Ball."
    end

    local transferred, reason = PokemonRepository.transferOwnership(instanceId, storedOwnerGuid, playerGuid)
    if not transferred then return nil, reason end

    -- originalTrainer is deliberately immutable. Only current ownership moves.
    ball:setCustomAttribute("hakai.pokemon.ownerGuid", playerGuid)
    return transferred
end

local function spawnInstance(player, instance, teamSlot)
	local instanceId = tostring(instance.instanceId)
	local current = PokemonSummon.get(player)
	if current and current.instanceId == instanceId then
		local dismissed, dismissReason = PokemonSummon.dismiss(player)
		if not dismissed then return false, dismissReason end
		return true, "Pokemon returned to its Poke Ball."
	end
    if (tonumber(instance.currentHp) or 0) <= 0 or instance.state == "fainted" then
        return false, "This Pokemon is fainted and needs healing."
    end
    local species = PokemonSpecies.get(instance.speciesId)
    local monster
    for _, offset in ipairs(offsets) do
        local position = player:getPosition()
        position.x, position.y = position.x + offset[1], position.y + offset[2]
        monster = Game.createMonster(species.name, position, true, false, player)
        if monster then break end
    end
    if not monster then return false, "There is no room to release this Pokemon." end
	if current then
		local dismissed, dismissReason = PokemonSummon.dismiss(player)
		if not dismissed then
			monster:remove()
			return false, dismissReason
		end
	end
    local maximumHp = math.max(tonumber(instance.maxHp) or monster:getMaxHealth(), 1)
    local currentHp = math.max(math.min(tonumber(instance.currentHp) or maximumHp, maximumHp), 1)
    monster:setMaxHealth(maximumHp)
    local healthDifference = currentHp - monster:getHealth()
    if healthDifference ~= 0 then monster:addHealth(healthDifference) end
    instance.maxHp = maximumHp
    instance.currentHp = currentHp
    instance.state = "ready"
    instance.runtimeCreatureId = monster:getId()
    instance.isSummon = true
    PokemonEncounter.active[monster:getId()] = instance
    PokemonEncounter.applyRuntimeCombatProfile(monster, instance)
	monster:setPokemonPlayerControlled(true)
    PokemonSummon.active[key(player)] = {
        creatureId=monster:getId(),
        instanceId=instanceId,
        instance=instance,
        playerId=player:getId(),
		teamSlot=teamSlot,
    }
    if PokemonTargetPolicy then PokemonTargetPolicy.onSummonReleased(player, monster) end
    return true, "Go, " .. species.name .. "!"
end

function PokemonSummon.releaseInstance(player, instanceId)
    instanceId = tostring(instanceId)
    local teamSlot = PokemonTeam.findSlotForInstance(player, instanceId)
    if not teamSlot then
        return false, "Only Pokemon assigned to your Team can be summoned."
    end
    return PokemonSummon.releaseTeamSlot(player, teamSlot)
end

function PokemonSummon.releaseCaptureBagSlot(player, slot)
    return false, "Assign this Pokemon to a Team slot before summoning it."
end

function PokemonSummon.releaseTeamSlot(player, slot)
    local instance, _, reason = PokemonTeam.getInstanceForSummon(player, slot)
    if not instance then return false, reason end
    return spawnInstance(player, instance, slot)
end

function PokemonSummon.release(player, ball)
    return false, "Pokemon are summoned from Team slots. Open your Pokemon Team."
end

