-- Server-authoritative guard for roster mutations during a Pokemon battle.
-- A short grace window covers the interval after the last real hit, including
-- attacks that kill the target and therefore no longer have a live target.
PokemonBattleLock = {
    GRACE_SECONDS = 10,
    untilByOwnerGuid = {},
}

local function ownerGuid(player)
    return player and player:isPlayer() and player:getGuid() or nil
end

function PokemonBattleLock.mark(player)
    local guid = ownerGuid(player)
    if not guid then return false end
    local untilTime = os.time() + PokemonBattleLock.GRACE_SECONDS
    PokemonBattleLock.untilByOwnerGuid[guid] = math.max(PokemonBattleLock.untilByOwnerGuid[guid] or 0, untilTime)
    return true
end

function PokemonBattleLock.markBySummonCreature(creature)
    if not creature or not PokemonSummon then return false end
    local active = PokemonSummon.getByCreature(creature:getId())
    if not active then return false end
    return PokemonBattleLock.mark(Player(active.playerId))
end

function PokemonBattleLock.isLocked(player)
    local guid = ownerGuid(player)
    if not guid then return false, 0 end
    local remaining = math.max(0, (PokemonBattleLock.untilByOwnerGuid[guid] or 0) - os.time())
    if remaining == 0 then PokemonBattleLock.untilByOwnerGuid[guid] = nil end
    return remaining > 0, remaining
end

function PokemonBattleLock.reason(player)
    local locked, remaining = PokemonBattleLock.isLocked(player)
    if not locked then return nil end
    return string.format("You cannot change Pokemon Team or Capture Bag during battle (%ds).", remaining)
end

function PokemonBattleLock.clear(playerOrGuid)
    local guid = type(playerOrGuid) == "number" and playerOrGuid or ownerGuid(playerOrGuid)
    if guid then PokemonBattleLock.untilByOwnerGuid[guid] = nil end
end
