-- Trainers may still select a creature as the target for their active Pokemon,
-- but all direct Player -> Monster combat must be rejected by the native combat
-- pipeline. Pokemon moves are cast by the summoned Monster, not by the Player.
local trainerCombatLock = CreatureEvent("PokemonTrainerCombatLock")

function trainerCombatLock.onLogin(player)
    player:setGroupFlag(PlayerFlag_CannotAttackMonster)
    return true
end

trainerCombatLock:register()
