local pokemonRosterOpcode = CreatureEvent("PokemonRosterOpcode")

function pokemonRosterOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode == PokemonRosterProtocol.OPCODE then
		PokemonRosterProtocol.handle(player, buffer)
	elseif opcode == NurseJoyInteraction.OPCODE then
		NurseJoyInteraction.handleRequest(player, buffer)
	end
end

pokemonRosterOpcode:register()
