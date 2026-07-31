local pokeBall = Action()

local function deliverCapture(playerId,deliveryId,instanceId,ballItemId,trainerName)
    local player=Player(playerId); if not player then return end
    local instance,reason=PokemonRepository.load(instanceId,player:getGuid())
    if not instance then logger.error("[PokemonCapture] Cannot load queued instance {}: {}",instanceId,reason); return end
    if deliveryId then
        PokemonRepository.markCaptureDelivered(deliveryId,player:getGuid())
    end
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE,string.format(
        "Success! %s was sent to Capture Bag slot %d.",
        PokemonSpecies.get(instance.speciesId).name,
        instance.locationSlot
    ))
    if PokemonRosterProtocol then
        PokemonRosterProtocol.snapshot(player, false, string.format("%s entered Capture Bag slot %d.", PokemonSpecies.get(instance.speciesId).name, instance.locationSlot), true)
    end
end

function PokemonCapture.schedulePendingDeliveries(player)
    for _,delivery in ipairs(PokemonRepository.pendingCaptureDeliveries(player:getGuid())) do
        addEvent(deliverCapture,math.max(1,delivery.remainingMs),player:getId(),delivery.deliveryId,delivery.instanceId,delivery.ballItemId,delivery.trainerName)
    end
end

local function playResult(playerId,x,y,z,effectId,message)
    Position(x,y,z):sendMagicEffect(effectId); local player=Player(playerId); if player and message then player:sendTextMessage(MESSAGE_FAILURE,message) end
end

local function confirmCapture(playerId,x,y,z,speciesName)
    Position(x,y,z):sendMagicEffect(CONST_ME_MAGIC_GREEN)
    local player=Player(playerId)
    if not player then return end
    player:sendTextMessage(MESSAGE_GAME_HIGHLIGHT,"CAPTURED!")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE,string.format("%s was successfully captured!",speciesName))
end

function pokeBall.onUse(player,item,fromPosition,target,toPosition)
    local entry=PokemonBalls.fromItemId(item:getId()); if not entry or entry.state~="empty" then return false end
    if not PokemonCapture.isEligibleTrainer(player) then
        player:sendTextMessage(MESSAGE_FAILURE,"Only registered Trainers can capture Pokemon.")
        return true
    end
    if player:getPosition():getDistance(toPosition)>7 then player:sendTextMessage(MESSAGE_FAILURE,"The fainted Pokemon is too far away."); return true end
    local corpse,encounter,reason=PokemonCapture.findReadyCorpse(toPosition,target)
    if not corpse then
        local message = reason == "capture attempt already consumed"
            and "A capture attempt was already made on this corpse."
            or "Use this Poke Ball on a fainted Pokemon."
        player:sendTextMessage(MESSAGE_FAILURE,message)
        logger.debug("[PokemonCapture] Rejected tile ({}, {}, {}): {}",toPosition.x,toPosition.y,toPosition.z,reason)
        return true
    end
    local authorized,authorizationReason=PokemonCapture.authorize(corpse,player)
    if not authorized then
        local message = authorizationReason == "corpse belongs to another Trainer"
            and "This fainted Pokemon belongs to another Trainer."
            or "This fainted Pokemon cannot be captured."
        player:sendTextMessage(MESSAGE_FAILURE,message)
        logger.debug("[PokemonCapture] Unauthorized capture attempt by player {}: {}",player:getGuid(),authorizationReason)
        return true
    end
    local hasSpace,_,capacity=PokemonCaptureBag.hasSpace(player:getGuid())
    if not hasSpace then
        player:sendTextMessage(MESSAGE_FAILURE,string.format("Your Capture Bag is full (%d/%d).",capacity,capacity))
        return true
    end
    if not PokemonCapture.tryLockCorpse(corpse) then player:sendTextMessage(MESSAGE_FAILURE,"A capture attempt was already made on this corpse."); return true end
    local definition,species=entry.definition,PokemonSpecies.get(encounter.speciesId)
    local success=math.random()<=PokemonCapture.calculateChance(species,definition,0)
    local playerId,x,y,z=player:getId(),toPosition.x,toPosition.y,toPosition.z
    if not success then
        player:getPosition():sendDistanceEffect(toPosition,definition.projectileId)
        item:remove(1)
        if PokemonCapture.shouldPreserveCorpseAfterFailure() then
            PokemonCapture.unlockCorpse(corpse)
        else
            corpse:remove(1)
        end
        addEvent(playResult,500,playerId,x,y,z,definition.failureEffectId,string.format("%s escaped from the Poke Ball.",species.name))
        return true
    end

    -- Persist first. If this internal step fails, neither the ball nor the
    -- corpse is consumed and the player can safely retry.
    local instance,persistReason=PokemonRepository.createCaptured(encounter,player:getGuid(),"capture",definition.capturedItemId)
    if not instance then
        PokemonCapture.unlockCorpse(corpse)
        player:sendTextMessage(MESSAGE_FAILURE,"The capture could not be saved. Your Poke Ball was not consumed.")
        logger.error("[PokemonCapture] Persistence failed: {}",persistReason)
        return true
    end
    local deliveryId,queueReason=PokemonRepository.queueCaptureDelivery(instance,player:getName(),definition.capturedItemId,500+PokemonCapture.SUCCESS_ANIMATION_MS)
    if not deliveryId then
        -- The instance already exists authoritatively in Capture Bag. Continue
        -- visual delivery; a relog also rebuilds the roster from persistence.
        logger.error("[PokemonCapture] Queue failed for {}: {}",instance.instanceId,queueReason)
        deliveryId = false
    end
    player:getPosition():sendDistanceEffect(toPosition,definition.projectileId)
    item:remove(1)
    corpse:remove(1)
    addEvent(playResult,500,playerId,x,y,z,definition.successEffectId,nil)
    addEvent(confirmCapture,500+PokemonCapture.SUCCESS_ANIMATION_MS,playerId,x,y,z,species.name)
    addEvent(deliverCapture,500+PokemonCapture.SUCCESS_ANIMATION_MS,playerId,deliveryId,instance.instanceId,definition.capturedItemId,player:getName())
    return true
end
pokeBall:id(54267, 54420, 54422, 54424)
pokeBall:allowFarUse(true)
pokeBall:register()
