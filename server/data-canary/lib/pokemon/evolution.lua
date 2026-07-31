PokemonEvolution = {
    MODES = {
        LEVEL = "level",
        STONE = "stone",
        LEVEL_STONE = "level_stone",
    },
}

local methodAliases = {
    ["level"] = PokemonEvolution.MODES.LEVEL,
    ["level-up"] = PokemonEvolution.MODES.LEVEL,
    ["stone"] = PokemonEvolution.MODES.STONE,
    ["use-item"] = PokemonEvolution.MODES.STONE,
    ["level_stone"] = PokemonEvolution.MODES.LEVEL_STONE,
    ["level-stone"] = PokemonEvolution.MODES.LEVEL_STONE,
}

local function copyTable(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = type(value) == "table" and copyTable(value) or value
    end
    return copy
end

local function integer(value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) then
        return nil
    end
    return value
end

function PokemonEvolution.normalizeRoute(route)
    assert(type(route) == "table", "evolution route must be a table")

    route.targetSpeciesId = integer(route.targetSpeciesId or route.speciesId)
    route.mode = route.mode or methodAliases[route.method]
    route.level = integer(route.level or route.minLevel)
    route.stone = route.stone or route.item
    if route.consumeStone == nil then
        route.consumeStone = true
    end

    if not route.targetSpeciesId or route.targetSpeciesId <= 0 then
        route.executable = false
        route.unavailableReason = "evolution target species is invalid"
        return route
    end
    if not methodAliases[route.mode] then
        route.executable = false
        route.unavailableReason = "evolution method is outside the approved level/stone/level_stone contract"
        return route
    end
    route.mode = methodAliases[route.mode]
    if (route.mode == PokemonEvolution.MODES.LEVEL or route.mode == PokemonEvolution.MODES.LEVEL_STONE)
        and (not route.level or route.level < 1)
    then
        route.executable = false
        route.unavailableReason = "evolution level is required"
        return route
    end
    if (route.mode == PokemonEvolution.MODES.STONE or route.mode == PokemonEvolution.MODES.LEVEL_STONE)
        and route.stone == nil and route.stoneItemId == nil
    then
        route.executable = false
        route.unavailableReason = "evolution stone is required"
        return route
    end

    route.executable = true
    route.unavailableReason = nil
    return route
end

function PokemonEvolution.normalizeSpecies(species)
    local routes = species.evolutions
    if routes == nil then
        routes = species.evolution and { species.evolution } or {}
        species.evolutions = routes
    end
    assert(type(routes) == "table", "species.evolutions must be a table")
    for _, route in ipairs(routes) do
        PokemonEvolution.normalizeRoute(route)
    end
    if species.evolution then
        PokemonEvolution.normalizeRoute(species.evolution)
    end
    return species
end

function PokemonEvolution.routesFor(speciesId)
    local species = PokemonSpecies.get(speciesId)
    if not species then
        return {}
    end
    PokemonEvolution.normalizeSpecies(species)
    return species.evolutions
end

local function stoneMatches(route, stone)
    if stone == nil then
        return false
    end
    if route.stoneItemId ~= nil and tonumber(stone) == tonumber(route.stoneItemId) then
        return true
    end
    return route.stone ~= nil and tostring(stone) == tostring(route.stone)
end

function PokemonEvolution.isEligible(instance, route, trigger, stone)
    if type(instance) ~= "table" or type(route) ~= "table" then
        return false, "missing Pokemon instance or evolution route"
    end
    PokemonEvolution.normalizeRoute(route)
    if not route.executable then
        return false, route.unavailableReason
    end
    if not PokemonSpecies.get(route.targetSpeciesId) then
        return false, "evolution target is unavailable in the active catalog"
    end

    if route.mode == PokemonEvolution.MODES.LEVEL then
        if trigger ~= PokemonEvolution.MODES.LEVEL then
            return false, "this evolution is triggered automatically by level"
        end
        return instance.level >= route.level, "required level not reached"
    end

    if trigger ~= PokemonEvolution.MODES.STONE then
        return false, "this evolution requires a stone"
    end
    if not stoneMatches(route, stone) then
        return false, "incorrect evolution stone"
    end
    if route.mode == PokemonEvolution.MODES.LEVEL_STONE and instance.level < route.level then
        return false, "required level not reached"
    end
    return true
end

function PokemonEvolution.findEligible(instance, trigger, stone, targetSpeciesId)
    for _, route in ipairs(PokemonEvolution.routesFor(instance.speciesId)) do
        if targetSpeciesId == nil or tonumber(targetSpeciesId) == route.targetSpeciesId then
            local eligible, reason = PokemonEvolution.isEligible(instance, route, trigger, stone)
            if eligible then
                return route
            end
            if targetSpeciesId ~= nil then
                return nil, reason
            end
        end
    end
    return nil, "no eligible evolution route"
end

function PokemonEvolution.apply(instance, route)
    PokemonEvolution.normalizeRoute(route)
    local eligible, reason = PokemonEvolution.isEligible(
        instance,
        route,
        route.mode == PokemonEvolution.MODES.LEVEL and PokemonEvolution.MODES.LEVEL or PokemonEvolution.MODES.STONE,
        route.stoneItemId or route.stone
    )
    if not eligible then
        return nil, reason
    end

    local evolved = copyTable(instance)
    local targetSpecies = PokemonSpecies.get(route.targetSpeciesId)
    local previousMaximum = math.max(tonumber(instance.maxHp) or 1, 1)
    local previousCurrent = math.max(tonumber(instance.currentHp) or 0, 0)
    local healthRatio = math.min(previousCurrent / previousMaximum, 1)
    local calculated = PokemonStats.calculate(targetSpecies, instance.level, instance.ivs, instance.nature, instance.gender)

    evolved.speciesId = route.targetSpeciesId
    evolved.maxHp = math.max(calculated.hp, 1)
    if previousCurrent == 0 or instance.state == "fainted" then
        evolved.currentHp = 0
    else
        evolved.currentHp = math.max(1, math.min(evolved.maxHp, math.floor(evolved.maxHp * healthRatio + 0.5)))
    end
    return evolved
end

function PokemonEvolution.evolveStoredByLevel(player, instanceId, options)
    options = options or {}
    local instance, loadReason = PokemonRepository.load(tostring(instanceId), player:getGuid())
    if not instance then
        return nil, loadReason
    end
    local active = PokemonSummon and PokemonSummon.get(player)
    if active and tostring(active.instanceId) == tostring(instance.instanceId) and not options.allowActive then
        return nil, "Recall the Pokemon before it evolves."
    end

    local route, routeReason = PokemonEvolution.findEligible(instance, PokemonEvolution.MODES.LEVEL)
    if not route then
        return nil, routeReason
    end
    local evolved, applyReason = PokemonEvolution.apply(instance, route)
    if not evolved then
        return nil, applyReason
    end
    local persisted, persistReason = PokemonRepository.persistEvolution(instance, evolved)
    if not persisted then
        return nil, persistReason
    end
    if PokemonTeam then
        local teamSession = PokemonTeam.ensureLoaded(player)
        teamSession.revision = teamSession.revision + 1
    end
    if active and tostring(active.instanceId) == tostring(persisted.instanceId) and options.allowActive then
        PokemonSummon.refreshActiveInstance(player, persisted, instance.speciesId)
    end
    if PokemonRosterProtocol and not options.suppressSnapshot then
        PokemonRosterProtocol.snapshot(
            player,
            false,
            string.format("%s evolved into %s.", PokemonSpecies.get(instance.speciesId).name, PokemonSpecies.get(evolved.speciesId).name),
            true
        )
    end
    return persisted
end
