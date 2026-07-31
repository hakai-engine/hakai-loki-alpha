local fly = TalkAction("/fly")
function fly.onSay(player, words, param)
    local action=param:lower():match("^%s*(.-)%s*$")
    local ok,message
    if action=="up" or action=="h1" then ok,message=PokemonTravel.changeAltitude(player,-1)
    elseif action=="down" or action=="h2" then ok,message=PokemonTravel.changeAltitude(player,1)
    elseif action=="" then if PokemonTravel.isFlying(player) then ok,message=PokemonTravel.exit(player) else ok,message=PokemonTravel.enter(player) end
    else ok,message=false,"Use /fly, /fly up or /fly down." end
    if ok then player:sendTextMessage(MESSAGE_EVENT_ADVANCE,message) else player:sendTextMessage(MESSAGE_FAILURE,message) end
    return false
end
fly:separator(" ")
fly:groupType("normal")
fly:register()

