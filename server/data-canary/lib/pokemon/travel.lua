PokemonTravel = { sessions = {} }

local CHARIZARD_FLY_OUTFIT = 4185
local SURF_OUTFITS = {
    [7] = 4162, -- Squirtle
    [8] = 4163, -- Wartortle
    [9] = 4164, -- Blastoise
}
local CARDINAL_OFFSETS = {
    { x = 0, y = -1 },
    { x = 1, y = 0 },
    { x = 0, y = 1 },
    { x = -1, y = 0 },
}

local function key(player)
    return player:getGuid()
end

local function clone(value)
    local result = {}
    for k, v in pairs(value) do
        result[k] = v
    end
    return result
end

local function groundId(position)
    local tile = Tile(position)
    local ground = tile and tile:getGround()
    return ground and ground:getId() or nil
end

local function isWaterGroundId(itemId)
    if not itemId then
        return false
    end
    for _, waterId in ipairs(swimmingTiles or {}) do
        if itemId == waterId then
            return true
        end
    end
    return false
end

local function adjacentPosition(player, predicate)
    local origin = player:getPosition()
    for _, offset in ipairs(CARDINAL_OFFSETS) do
        local position = Position(origin.x + offset.x, origin.y + offset.y, origin.z)
        if predicate(position) then
            return position
        end
    end
    return nil
end

function PokemonTravel.get(player)
    return PokemonTravel.sessions[key(player)]
end

function PokemonTravel.isMode(player, mode)
    local session = PokemonTravel.get(player)
    return session ~= nil and session.mode == mode
end

function PokemonTravel.isFlying(player)
    return PokemonTravel.isMode(player, "fly")
end

function PokemonTravel.isSurfing(player)
    return PokemonTravel.isMode(player, "surf")
end

function PokemonTravel.isWaterPosition(position)
    return isWaterGroundId(groundId(position))
end

function PokemonTravel.enter(player)
    if PokemonTravel.get(player) then
        return false, "Finish your current travel mode first."
    end

    local active = PokemonSummon.get(player)
    if not active or active.instance.speciesId ~= 6 then
        return false, "Release a captured Charizard first."
    end

    local session = {
        mode = "fly",
        outfit = clone(player:getOutfit()),
        instanceId = active.instanceId,
        speciesId = active.instance.speciesId,
        altitude = 0,
    }
    PokemonSummon.dismiss(player)

    local outfit = clone(session.outfit)
    outfit.lookType = CHARIZARD_FLY_OUTFIT
    outfit.lookMount = 0
    player:setOutfit(outfit)
    PokemonTravel.sessions[key(player)] = session
    return true, "Charizard took flight."
end

function PokemonTravel.enterSurf(player, waterPosition, shorePosition)
    if PokemonTravel.get(player) then
        return false, "Finish your current travel mode first."
    end

    local active = PokemonSummon.get(player)
    local speciesId = active and active.instance.speciesId
    if not speciesId or not SURF_OUTFITS[speciesId] then
        return false, "Release Squirtle, Wartortle or Blastoise first."
    end

    local automaticTransition = waterPosition ~= nil
    waterPosition = waterPosition or adjacentPosition(player, PokemonTravel.isWaterPosition)
    if not waterPosition then
        return false, "Stand beside navigable water to use Surf."
    end

    local species = PokemonSpecies.get(speciesId)
    local lookType = SURF_OUTFITS[speciesId]
    if not lookType then
        return false, "This Pokemon has no Surf appearance configured."
    end

    local session = {
        mode = "surf",
        outfit = clone(player:getOutfit()),
        instanceId = active.instanceId,
        speciesId = speciesId,
        shorePosition = shorePosition or player:getPosition(),
        allowLand = false,
    }
    PokemonSummon.dismiss(player)

    local outfit = clone(session.outfit)
    outfit.lookType = lookType
    outfit.lookMount = 0
    player:setOutfit(outfit)
    PokemonTravel.sessions[key(player)] = session

    if not automaticTransition and not player:teleportTo(waterPosition, false) then
        PokemonTravel.sessions[key(player)] = nil
        player:setOutfit(session.outfit)
        return false, "The water tile rejected Surf."
    end

    waterPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
    return true, species.name .. " started surfing."
end

function PokemonTravel.finishSurfAt(player, landPosition)
    local session = PokemonTravel.get(player)
    if not session or session.mode ~= "surf" then
        return false, "You are not surfing."
    end
    if PokemonTravel.isWaterPosition(landPosition) then
        return false, "That position is still water."
    end

    player:setOutfit(session.outfit)
    PokemonTravel.sessions[key(player)] = nil
    landPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
    return true, "Returned safely to shore."
end

function PokemonTravel.changeAltitude(player, delta)
    local session = PokemonTravel.get(player)
    if not session or session.mode ~= "fly" then
        return false, "You are not flying."
    end

    local destination = player:getPosition()
    destination.z = destination.z + delta
    if destination.z < 0 or destination.z > 15 then
        return false, "That altitude is outside the map."
    end

    local tile = Tile(destination)
    if not tile or not tile:getGround() then
        return false, "There is no mapped floor at that altitude."
    end
    if tile:getHouse() or tile:hasFlag(TILESTATE_BLOCKSOLID) or tile:hasFlag(TILESTATE_BLOCKPATH) then
        return false, "That altitude is blocked."
    end
    if not player:teleportTo(destination, false) then
        return false, "The destination rejected the movement."
    end

    session.altitude = session.altitude - delta
    destination:sendMagicEffect(CONST_ME_TELEPORT)
    return true, delta < 0 and "Flying higher." or "Flying lower."
end

function PokemonTravel.exitSurf(player)
    local session = PokemonTravel.get(player)
    if not session or session.mode ~= "surf" then
        return false, "You are not surfing."
    end

    local landPosition = adjacentPosition(player, function(position)
        local tile = Tile(position)
        return tile
            and tile:getGround()
            and not PokemonTravel.isWaterPosition(position)
            and not tile:hasFlag(TILESTATE_BLOCKSOLID)
            and not tile:hasFlag(TILESTATE_BLOCKPATH)
    end)
    if not landPosition then
        return false, "There is no free shore beside you."
    end

    session.allowLand = true
    local moved = player:teleportTo(landPosition, false)
    session.allowLand = false
    if not moved then
        return false, "The shore rejected the landing."
    end

    return PokemonTravel.finishSurfAt(player, landPosition)
end

function PokemonTravel.exit(player)
    local session = PokemonTravel.get(player)
    if not session then
        return false, "You are not travelling."
    end
    if session.mode == "surf" then
        return PokemonTravel.exitSurf(player)
    end

    player:setOutfit(session.outfit)
    PokemonTravel.sessions[key(player)] = nil
    return true, "Landed safely."
end

function PokemonTravel.abort(player)
    local session = PokemonTravel.get(player)
    if session then
        if session.mode == "surf" and session.shorePosition then
            player:teleportTo(session.shorePosition, true)
        end
        player:setOutfit(session.outfit)
        PokemonTravel.sessions[key(player)] = nil
    end
    return true
end
