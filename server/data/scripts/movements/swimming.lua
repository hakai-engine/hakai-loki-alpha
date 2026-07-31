local condition = Condition(CONDITION_OUTFIT)
condition:setOutfit({ lookType = 267 })
condition:setTicks(-1)

local conditions = {
	CONDITION_POISON,
	CONDITION_FIRE,
	CONDITION_ENERGY,
	CONDITION_PARALYZE,
	CONDITION_DRUNK,
	CONDITION_DROWN,
	CONDITION_FREEZING,
	CONDITION_DAZZLED,
	CONDITION_CURSED,
	CONDITION_BLEEDING,
}

local swimming = MoveEvent()

function swimming.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	if PokemonTravel then
		if not PokemonTravel.isSurfing(player) then
			local ok, message = PokemonTravel.enterSurf(player, position, fromPosition)
			if not ok then
				player:teleportTo(fromPosition, true)
				player:sendTextMessage(MESSAGE_FAILURE, message)
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			end
			return true
		end

		-- Surf owns the appearance; the legacy swimming condition must not
		-- overwrite the selected Pokemon's travel outfit.
		return true
	end

	for i = 1, #conditions do
		player:removeCondition(conditions[i])
	end

	player:addCondition(condition)
	return true
end

swimming:type("stepin")
swimming:id(unpack(swimmingTiles))
swimming:register()

swimming = MoveEvent()

function swimming.onStepOut(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	if PokemonTravel and PokemonTravel.isSurfing(player) then
		local destination = player:getPosition()
		if not PokemonTravel.isWaterPosition(destination) then
			local ok, message = PokemonTravel.finishSurfAt(player, destination)
			if ok then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			end
		end
		return true
	end

	player:removeCondition(CONDITION_OUTFIT)
	return true
end

swimming:type("stepout")
swimming:id(unpack(swimmingTiles))
swimming:register()
