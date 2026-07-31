local captureBag = TalkAction("/pokemonbag")

local function showTeam(player)
    local slots = PokemonTeam.list(player)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Pokemon Team (6 slots):")
    for slot = 1, PokemonTeam.MAX_SLOTS do
        local instanceId = slots[slot]
        if not instanceId then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[%d] Empty", slot))
        else
            local entry = PokemonCaptureBag.getByInstanceId(player:getGuid(), instanceId)
            local species = entry and PokemonSpecies.get(entry.speciesId)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
                "[%d] %s Lv.%d | instance #%s",
                slot,
                species and species.name or "Unavailable Pokemon",
                entry and entry.level or 0,
                instanceId
            ))
        end
    end
end

local function showBag(player)
    local entries = PokemonCaptureBag.list(player:getGuid())
    local capacity = PokemonCaptureBag.capacity(player:getGuid())
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
		"Capture Bag: %d/%d slots used. Move a Pokemon to Team before summoning it.",
        #entries,
        capacity
    ))
    if #entries == 0 then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your Capture Bag is empty.")
        return
    end
    for _, entry in ipairs(entries) do
        local species = PokemonSpecies.get(entry.speciesId)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(
            "[%d] %s Lv.%d | %s | %s | instance #%s",
            entry.slot,
            species and species.name or ("Species " .. entry.speciesId),
            entry.level,
            entry.gender,
            entry.nature,
            entry.instanceId
        ))
    end
end

function captureBag.onSay(player, words, param)
    local action, first, second = param:lower():match("^%s*([%a]*)%s*,?%s*(%d*)%s*,?%s*(%d*)%s*$")
    if action == "" or action == "list" then
        if PokemonRosterProtocol then
            PokemonRosterProtocol.open(player, "bag")
        end
        showBag(player)
        return false
    end
    if action == "team" and first == "" then
        if PokemonRosterProtocol then
            PokemonRosterProtocol.open(player, "team")
        end
        showTeam(player)
        return false
    end
    if action == "team" then
        local bagSlot, teamSlot = tonumber(first), tonumber(second)
        if not bagSlot or not teamSlot then
            player:sendTextMessage(MESSAGE_FAILURE, "Use /pokemonbag team, BAG_SLOT, TEAM_SLOT.")
            return false
        end
        local ok, message = PokemonTeam.assignFromCaptureBag(player, bagSlot, teamSlot)
        if PokemonRosterProtocol then
            PokemonRosterProtocol.snapshot(player, "team", message, ok)
        end
        player:sendTextMessage(ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
        return false
    end
    if action == "remove" then
        local ok, message = PokemonTeam.remove(player, tonumber(first))
        if PokemonRosterProtocol then
            PokemonRosterProtocol.snapshot(player, "team", message, ok)
        end
        player:sendTextMessage(ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
        return false
    end
    if action == "go" then
        local ok, message = PokemonSummon.releaseTeamSlot(player, tonumber(first))
        if PokemonRosterProtocol then
            PokemonRosterProtocol.snapshot(player, "team", message, ok)
        end
        player:sendTextMessage(ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
        return false
    end
	if action == "use" then
		player:sendTextMessage(MESSAGE_FAILURE, "Capture Bag Pokemon must be assigned to Team before summoning.")
		return false
	end
    player:sendTextMessage(MESSAGE_FAILURE, "Use /pokemonbag, /pokemonbag team, /pokemonbag team BAG,TEAM, /pokemonbag remove TEAM, or /pokemonbag go TEAM.")
    return false
end

captureBag:separator(" ")
captureBag:groupType("normal")
captureBag:register()
