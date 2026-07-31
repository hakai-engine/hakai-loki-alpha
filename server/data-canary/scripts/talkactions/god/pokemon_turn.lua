local talkAction = TalkAction("/poketurn")

local directions = {
    north = DIRECTION_NORTH,
    norte = DIRECTION_NORTH,
    east = DIRECTION_EAST,
    leste = DIRECTION_EAST,
    south = DIRECTION_SOUTH,
    sul = DIRECTION_SOUTH,
    west = DIRECTION_WEST,
    oeste = DIRECTION_WEST,
}

function talkAction.onSay(player, words, param)
    local active = PokemonSummon and PokemonSummon.get(player)
    local monster = active and Monster(active.creatureId) or nil
    if not monster or monster:getHealth() <= 0 then
        player:sendCancelMessage("Release a healthy Pokemon before using /poketurn.")
        return false
    end

    local name = (param or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local direction = directions[name]
    if direction == nil then
        player:sendCancelMessage("Usage: /poketurn <north|east|south|west>")
        return false
    end

    monster:setDirection(direction)
    player:sendTextMessage(
        MESSAGE_EVENT_ADVANCE,
        string.format("%s is now facing %s.", monster:getName(), name)
    )
    return false
end

talkAction:separator(" ")
talkAction:groupType("god")
talkAction:register()
