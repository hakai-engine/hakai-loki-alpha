PokemonHealing = {}

function PokemonHealing.restore(player)
	local ownerGuid = player:getGuid()
	local updated, injured, total = PokemonRepository.healRoster(ownerGuid)
	if not updated then
		return false, 0, 0, "Pokemon persistence update failed"
	end

	-- Capture Bag is session-backed. Reload it from the repaired database;
	-- merely assigning currentHp = entry.maxHp would preserve a legacy 0/0.
	PokemonCaptureBag.load(player)

	local active = PokemonSummon and PokemonSummon.get(player)
	if active and active.instance then
		local refreshed, refreshReason = PokemonRepository.load(tostring(active.instanceId), ownerGuid)
		if not refreshed then
			return false, 0, total, refreshReason or "failed to reload active Pokemon after healing"
		end
		active.instance = refreshed
		active.instance.currentHp = active.instance.maxHp
		active.instance.state = "ready"

		local monster = Monster(active.creatureId)
		if monster then
			local missingHealth = monster:getMaxHealth() - monster:getHealth()
			if missingHealth > 0 then
				monster:addHealth(missingHealth)
			end
		end
	end

	local missingPlayerHealth = player:getMaxHealth() - player:getHealth()
	if missingPlayerHealth > 0 then
		player:addHealth(missingPlayerHealth)
	end
	local missingPlayerMana = player:getMaxMana() - player:getMana()
	if missingPlayerMana > 0 then
		player:addMana(missingPlayerMana)
	end

	if PokemonRosterProtocol then
		PokemonRosterProtocol.snapshot(
			player,
			false,
			string.format("%d/%d Pokemon restored.", total, total),
			true
		)
	end
	return true, injured, total
end
