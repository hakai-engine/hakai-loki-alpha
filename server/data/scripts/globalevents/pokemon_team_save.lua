local pokemonTeamSave = GlobalEvent("PokemonTeamSave")

function pokemonTeamSave.onShutdown()
	if not PokemonTeam then
		return true
	end
	if not PokemonTeam.saveAll(true) then
		logger.error("[PokemonTeam] One or more teams could not be saved during shutdown.")
	end
	return true
end

pokemonTeamSave:register()
