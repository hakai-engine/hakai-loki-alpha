local capturedBall = Action()

function capturedBall.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local success, message = PokemonSummon.release(player, item)
    if success then player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
    else player:sendTextMessage(MESSAGE_FAILURE, message) end
    return true
end

capturedBall:id(54268)
capturedBall:register()
