-- Authoritative player-controlled move execution for released Pokemon.
-- Cooldowns intentionally live on the active projection for this first UI slice;
-- persistence across recall/relog remains a separate schema contract.
PokemonMoveCasting = { active = {} }

local function clock()
    return os.time()
end

local function activeKey(player, instanceId)
    return string.format("%d:%s", player:getGuid(), tostring(instanceId))
end

local function cooldownSeconds(move)
    return math.max(1, math.ceil((tonumber(move.cooldown) or 1000) / 1000))
end

function PokemonMoveCasting.snapshot(player, active)
    if not active or not active.instance then return {} end
    local now = clock()
    local cooldowns = PokemonMoveCasting.active[activeKey(player, active.instance.instanceId)] or {}
    local result = {}
    for index, move in ipairs(PokemonMoves.forSpecies(active.instance.speciesId)) do
        -- Status scripting is still not exposed as a native controlled spell.
        -- Do not present a button that the authoritative runtime cannot execute.
        if move.category ~= "status" and (tonumber(move.power) or 0) > 0 then
            result[#result + 1] = {
                slot = index, id = move.id, name = move.name, type = move.type,
                category = move.category, cooldown = tonumber(move.cooldown) or 1000,
                availableAt = math.max(0, tonumber(cooldowns[move.id]) or 0),
                ready = (tonumber(cooldowns[move.id]) or 0) <= now,
                targetMode = move.targetMode or "target",
            }
        end
    end
    return result
end

function PokemonMoveCasting.cast(player, moveId)
    if type(moveId) ~= "string" or #moveId == 0 or #moveId > 64 then return false, "Invalid Pokemon move." end
    local active = PokemonSummon and PokemonSummon.get(player)
    if not active then return false, "Release a Pokemon first." end
    local monster = Monster(active.creatureId)
    if not monster or monster:getHealth() <= 0 then return false, "Your active Pokemon is not able to battle." end
    local move = PokemonMoves.get(moveId)
    if not move then return false, "Unknown Pokemon move." end
	if move.category == "status" or (tonumber(move.power) or 0) <= 0 then
		return false, "That status move is not yet available in the controlled Moves Bar."
	end
    local known = false
    for _, candidate in ipairs(PokemonMoves.forSpecies(active.instance.speciesId)) do
        if candidate.id == move.id then known = true break end
    end
    if not known then return false, "This Pokemon does not know that move." end

    local key = activeKey(player, active.instanceId)
    local cooldowns = PokemonMoveCasting.active[key] or {}
    PokemonMoveCasting.active[key] = cooldowns
    local now = clock()
    local availableAt = tonumber(cooldowns[move.id]) or 0
    if availableAt > now then return false, string.format("%s is cooling down (%ds).", move.name, availableAt - now) end

    local target = nil
    if (move.targetMode or "target") ~= "self" then
        target = player:getTarget()
        if not target or target:isRemoved() or target:getHealth() <= 0 then return false, "Select a valid target first." end
    end
    if not monster:castPokemonMove(move.id, target) then
        return false, "Move failed: target, range, line of sight or battle state is invalid."
    end
    cooldowns[move.id] = now + cooldownSeconds(move)
    return true, move.name .. " used!"
end

function PokemonMoveCasting.clear(player, instanceId)
    if player and instanceId then PokemonMoveCasting.active[activeKey(player, instanceId)] = nil end
end
