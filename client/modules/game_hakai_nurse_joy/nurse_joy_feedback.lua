local OPCODE = 203
local VERSION = 1
local DEFAULT_DURATION = 3500
local DEFAULT_LOOKTYPE = 4209

local feedbackWidget
local hideEvent

local function clearHideEvent()
  if hideEvent then
    removeEvent(hideEvent)
    hideEvent = nil
  end
end

local function destroyFeedback()
  clearHideEvent()
  if feedbackWidget then
    feedbackWidget:destroy()
    feedbackWidget = nil
  end
end

local function showFeedback(data)
  if not g_game.isOnline() then return end

  destroyFeedback()
  local mapPanel = modules.game_interface.getMapPanel()
  if not mapPanel then return end

  feedbackWidget = g_ui.loadUI('nurse_joy_feedback', mapPanel)
  feedbackWidget:setPhantom(true)

  local portrait = feedbackWidget:recursiveGetChildById('portrait')
  if portrait then
    portrait:setOutfit({ type = tonumber(data.lookType) or DEFAULT_LOOKTYPE })
  end

  local message = feedbackWidget:recursiveGetChildById('message')
  if message then
    message:setText(tostring(data.message or 'Seus Pokemon estao curados. Volte sempre!'))
  end

  feedbackWidget:raise()
  local duration = math.max(1000, math.min(6000, tonumber(data.duration) or DEFAULT_DURATION))
  hideEvent = scheduleEvent(destroyFeedback, duration)
end

local function onExtendedOpcode(_, opcode, buffer)
  if opcode ~= OPCODE then return end

  local ok, payload = pcall(json.decode, buffer)
  if not ok or type(payload) ~= 'table' or payload.version ~= VERSION then
    g_logger.error('[NurseJoyFeedback] Invalid protocol payload')
    return
  end
  if payload.action ~= 'nurse_joy.healed' or type(payload.data) ~= 'table' then
    return
  end
  showFeedback(payload.data)
  -- The balloon only presents the result. Ask for one final authoritative
  -- roster snapshot so recently changed UI widgets cannot retain stale HP.
  scheduleEvent(function()
    if g_game.isOnline() and modules.game_pokemon_roster and modules.game_pokemon_roster.refresh then
      modules.game_pokemon_roster.refresh(false)
    end
  end, 100)
end

function requestInteraction(npcId)
  if not g_game.isOnline() or not npcId then return false end
  local protocol = g_game.getProtocolGame()
  if not protocol then return false end
  protocol:sendExtendedOpcode(OPCODE, json.encode({
    version = VERSION,
    action = 'nurse_joy.interact',
    data = { npcId = npcId },
  }))
  return true
end

function init()
  ProtocolGame.registerExtendedOpcode(OPCODE, onExtendedOpcode)
  connect(g_game, { onGameEnd = destroyFeedback })
end

function terminate()
  disconnect(g_game, { onGameEnd = destroyFeedback })
  ProtocolGame.unregisterExtendedOpcode(OPCODE)
  destroyFeedback()
end
