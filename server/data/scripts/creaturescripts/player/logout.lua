local playerLogout = CreatureEvent("PlayerLogout")

function playerLogout.onLogout(player)
	if PokemonTravel then
		PokemonTravel.abort(player)
	end
	if PokemonSummon and PokemonSummon.get(player) then
		local dismissed, dismissReason = PokemonSummon.dismiss(player)
		if not dismissed then
			player:sendTextMessage(MESSAGE_FAILURE, dismissReason or "Your active Pokemon could not be saved. Logout was cancelled; please try again.")
			return false
		end
	end
	if PokemonTeam and not PokemonTeam.unload(player) then
		player:sendTextMessage(MESSAGE_FAILURE, "Your Pokemon team could not be saved. Logout was cancelled; please try again.")
		return false
	end
	if PokemonCaptureBag then
		PokemonCaptureBag.unload(player:getGuid())
	end

	local playerId = player:getId()

	if _G.NextUseStaminaTime[playerId] then
		_G.NextUseStaminaTime[playerId] = nil
	end

	if LastQuestlogUpdate then
		LastQuestlogUpdate[playerId] = nil
	end

	if PlayerTrackedMissionRemovalEvents and PlayerTrackedMissionRemovalEvents[playerId] and player.flushTrackedMissionRemovalEvents then
		player:flushTrackedMissionRemovalEvents(false)
	end

	if PlayerTrackedMissionsData then
		if PlayerTrackedMissionsData[playerId] and player.saveTrackedMissions then
			player:saveTrackedMissions()
		end
		PlayerTrackedMissionsData[playerId] = nil
	end

	if PlayerTrackedMissionRemovalEvents then
		PlayerTrackedMissionRemovalEvents[playerId] = nil
	end

	if PlayerQuestTrackerInitialSync then
		PlayerQuestTrackerInitialSync[playerId] = nil
	end

	local stats = player:inBossFight()
	if stats then
		local boss = Monster(stats.bossId)
		if boss then
			local dmgOut = boss:getDamageMap()[playerId]
			if dmgOut then
				stats.damageOut = (stats.damageOut or 0) + dmgOut.total
			end

			stats.stamina = player:getStamina()
		end
	end

	if _G.OnExerciseTraining[playerId] then
		stopEvent(_G.OnExerciseTraining[playerId].event)
		_G.OnExerciseTraining[playerId] = nil
		player:setTraining(false)
	end
	return true
end

playerLogout:register()
