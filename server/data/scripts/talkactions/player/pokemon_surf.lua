local surf = TalkAction("/surf")

function surf.onSay(player, words, param)
    local ok
    local message
    if PokemonTravel.isSurfing(player) then
        ok, message = PokemonTravel.exitSurf(player)
    else
        ok, message = PokemonTravel.enterSurf(player)
    end

    player:sendTextMessage(ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
    return false
end

surf:groupType("normal")
surf:register()
