local OPCODE = 204
local shakeGeneration = 0

local function split(value, separator)
  local result = {}
  for token in string.gmatch(value or '', '([^' .. separator .. ']+)') do
    result[#result + 1] = token
  end
  return result
end

local function shakeMap(intensity, duration)
  local panel = modules.game_interface.getMapPanel()
  if not panel or intensity <= 0 or duration <= 0 then return end
  shakeGeneration = shakeGeneration + 1
  local generation = shakeGeneration
  local baseLeft, baseTop = panel:getMarginLeft(), panel:getMarginTop()
  local elapsed, step = 0, 30

  local function tick()
    if generation ~= shakeGeneration or not panel then return end
    if elapsed >= duration then
      panel:setMarginLeft(baseLeft)
      panel:setMarginTop(baseTop)
      return
    end
    panel:setMarginLeft(baseLeft + math.random(-intensity, intensity))
    panel:setMarginTop(baseTop + math.random(-intensity, intensity))
    elapsed = elapsed + step
    scheduleEvent(tick, step)
  end
  tick()
end

local function jumpCreatures(csv, height, duration)
  for id in string.gmatch(csv or '', '([^,]+)') do
    local creature = g_map.getCreatureById(tonumber(id))
    if creature and height > 0 and duration > 0 then
      creature:jump(height, duration)
    end
  end
end

local function clampedNumber(value, minimum, maximum)
  value = tonumber(value) or 0
  return math.max(minimum, math.min(maximum, value))
end

local function onCombatFx(_, opcode, buffer)
  if opcode ~= OPCODE then return end
  local fields = split(buffer, '|')
  if not fields[1] or fields[1] == '' or #fields < 5 then return end
  local intensity = clampedNumber(fields[2], 0, 12)
  local shakeDuration = clampedNumber(fields[3], 0, 1000)
  local jumpHeight = clampedNumber(fields[4], 0, 30)
  local jumpDuration = clampedNumber(fields[5], 0, 1000)
  shakeMap(intensity, shakeDuration)
  jumpCreatures(fields[6], jumpHeight, jumpDuration)
end

function init()
  ProtocolGame.registerExtendedOpcode(OPCODE, onCombatFx)
end

function terminate()
  shakeGeneration = shakeGeneration + 1
  ProtocolGame.unregisterExtendedOpcode(OPCODE)
end
