local captureDeliveryLogin=CreatureEvent("PokemonCaptureDeliveryLogin")
function captureDeliveryLogin.onLogin(player)
    PokemonCapture.schedulePendingDeliveries(player)
    return true
end
captureDeliveryLogin:register()
