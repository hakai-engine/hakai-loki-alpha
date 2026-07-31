PokemonTargetPolicy = {}

local VIEW_RANGE_X = 8
local VIEW_RANGE_Y = 6

local function activeSummon(player)
    if not player or not player:isPlayer() or not PokemonSummon then
        return nil
    end
    local active = PokemonSummon.get(player)
    if not active then return nil end
    local summon = Monster(active.creatureId)
    if not summon or summon:getHealth() <= 0 then return nil end
    return summon
end

local function isWildPokemon(monster)
    return monster
        and monster:isMonster()
        and not monster:getMaster()
        and PokemonEncounter
        and PokemonEncounter.get(monster) ~= nil
end

local function redirectTrainer(monster, trainer)
    local summon = activeSummon(trainer)
    if not summon then return false end

    monster:removeTarget(trainer)
    monster:addTarget(summon, true)
    monster:selectTarget(summon)
    return true
end

function PokemonTargetPolicy.enforce(monster)
    if not isWildPokemon(monster) then return true end

    local current = monster:getTarget()
    if current and current:isPlayer() and redirectTrainer(monster, current) then
        return true
    end

    for _, candidate in ipairs(monster:getTargetList()) do
        if candidate:isPlayer() and redirectTrainer(monster, candidate) then
            return true
        end
    end
    return true
end

local function nearbyWildPokemon(player)
    local monsters = {}
    for _, spectator in ipairs(Game.getSpectators(
        player:getPosition(), false, false,
        VIEW_RANGE_X, VIEW_RANGE_X, VIEW_RANGE_Y, VIEW_RANGE_Y
    )) do
        if spectator:isMonster() and isWildPokemon(spectator) then
            monsters[#monsters + 1] = spectator
        end
    end
    return monsters
end

function PokemonTargetPolicy.onSummonReleased(player, summon)
    if not player or not summon then return end
    for _, monster in ipairs(nearbyWildPokemon(player)) do
        monster:removeTarget(player)
        monster:addTarget(summon, true)
        monster:selectTarget(summon)
    end
end

function PokemonTargetPolicy.onSummonDismissed(player)
    if not player then return end
    for _, monster in ipairs(nearbyWildPokemon(player)) do
        monster:addTarget(player, true)
        monster:selectTarget(player)
    end
end
