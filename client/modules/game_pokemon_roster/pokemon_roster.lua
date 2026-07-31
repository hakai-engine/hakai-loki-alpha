pokemonRosterController = Controller:new()

local OPCODE = 202
local VERSION = 1
local state = {
  revision = 0,
  capacity = 20,
  bag = {},
  team = {},
  activeInstanceId = false,
  activeCreatureId = false,
  moves = {},
  serverTime = 0,
  pendingMoves = {},
  selectedBagSlot = nil,
}

local bagWindow
local teamWindow
local quickBar
local quickBarSlots
local bagList
local teamSlots
local topActionBar
local rosterButton
local lockButton
local activePortrait
local activeName
local activeDescription
local activeHealth
local activeHealthText
local activeActionButton
local syncStatus
local pokeInfoBar
local moveBar
local moveSlots
local teamLocked = true
local quickBarCompact = false

local function revealBag()
  if not bagWindow then return end
  bagWindow:show()
  bagWindow:raise()
  bagWindow:focus()
end

local function revealTeam()
  if not teamWindow then return end
  teamWindow:show()
  teamWindow:raise()
  if rosterButton then rosterButton:setOn(true) end
end

local function send(action, data)
  data = data or {}
  data.revision = state.revision
  pokemonRosterController:sendExtendedOpcode(OPCODE, json.encode({
    version = VERSION,
    action = action,
    data = data,
  }))
end

local function setCreature(widget, lookType, creatureSize)
  if widget and lookType and lookType > 0 then
    if creatureSize then
      widget:setCreatureSize(creatureSize)
    end
    widget:setOutfit({ type = lookType })
  end
end

local function clearChildren(widget)
  if not widget then return end
  widget:destroyChildren()
end

local function displayNature(nature)
  local value = tostring(nature or '')
  if value == '' then return 'Unknown' end
  local display = value:gsub('^%l', string.upper)
  return display
end

local function genderPresentation(gender)
  if gender == 'male' then
    return '♂', '#69b7ff', 'Macho',
      '/images/game/pokemon_team/gender_symbols/gender_male_20'
  elseif gender == 'female' then
    return '♀', '#ff87bd', 'Fêmea',
      '/images/game/pokemon_team/gender_symbols/gender_female_20'
  end
  return '—', '#b8c7ce', 'Sem gênero',
    '/images/game/pokemon_team/gender_symbols/gender_genderless_20'
end

local teamMember
local showFeedback
local renderActive
local renderQuickBar
local renderPokeInfo
local renderMoves
local dropTeamMemberIntoBag

local function updateBattleHudVisibility()
  local visible = state.activeInstanceId ~= false and state.activeCreatureId ~= false
  if pokeInfoBar then pokeInfoBar:setVisible(visible) end
  if moveBar then moveBar:setVisible(visible) end
end

local function setupQuickBarDrag()
  if not quickBar then return end
  local dragHandle = quickBar:recursiveGetChildById('quickBarHeader')
  if not dragHandle then return end

  dragHandle:setDraggable(true)
  dragHandle.onDragEnter = function(_, mousePos)
    return quickBar:onDragEnter(mousePos)
  end
  dragHandle.onDragMove = function(_, mousePos, mouseMoved)
    quickBar:onDragMove(mousePos, mouseMoved)
    return true
  end
  dragHandle.onDragLeave = function(_, droppedWidget, mousePos)
    quickBar:onDragLeave(droppedWidget, mousePos)
    local position = quickBar:getPosition()
    if position.x < 8 or position.y < 8 then
      quickBar:setPosition({ x = math.max(8, position.x), y = math.max(8, position.y) })
      position = quickBar:getPosition()
    end
    g_settings.set('pokemonQuickBarPositionX', position.x)
    g_settings.set('pokemonQuickBarPositionY', position.y)
    g_settings.set('pokemonQuickBarPositionSaved', true)
    return true
  end

  if g_settings.getBoolean('pokemonQuickBarPositionSaved', false) then
    quickBar:breakAnchors()
    quickBar:setPosition({
      x = math.max(8, g_settings.getNumber('pokemonQuickBarPositionX', 10)),
      y = math.max(8, g_settings.getNumber('pokemonQuickBarPositionY', 50)),
    })
    quickBar:bindRectToParent()
  end
end

local function enableRosterDrag(widget)
  widget.onDragEnter = function(self)
    if teamLocked then
      showFeedback('Clique em LOCKED para liberar o drag and drop.', false)
      return false
    end
    self:setBorderWidth(2)
    self.pokemonDragging = true
    g_mouse.pushCursor('target')
    return true
  end
  widget.onDragMove = function()
    return true
  end
  widget.onDragLeave = function(self)
    self:setBorderWidth(1)
    if self.pokemonDragging then
      self.pokemonDragging = false
      g_mouse.popCursor('target')
    end
    return true
  end
end

local function renderBag()
  if not bagList then return end
  clearChildren(bagList)
  local status = bagWindow:recursiveGetChildById('bagStatus')
  status:setText(string.format('CAPTURE BAG  %d / %d', #state.bag, state.capacity))

  for _, member in ipairs(state.bag) do
    local card = g_ui.createWidget('PokemonRosterCard', bagList)
    card:setId('pokemonBagSlot' .. member.bagSlot)
    card:setText(string.format('%s\nLv.%d  %s\nSlot %d', member.name, member.level, member.gender, member.bagSlot))
    card:setChecked(state.selectedBagSlot == member.bagSlot)
    card:setTooltip(string.format('%s | %s | Instance %s', member.nature, member.state, member.instanceId))
    card.pokemonBagSlot = member.bagSlot
    card:setDraggable(not teamLocked)
    enableRosterDrag(card)

    local portrait = g_ui.createWidget('UICreature', card)
    portrait:setSize({ width = 64, height = 64 })
    portrait:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    portrait:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    portrait:setMarginLeft(4)
    portrait:setPhantom(true)
    setCreature(portrait, member.lookType, 52)

    card.onClick = function()
      state.selectedBagSlot = member.bagSlot
      renderBag()
    end
    card.onDoubleClick = function()
      if teamLocked then
        showFeedback('Desbloqueie o time para adicionar Pokemon.', false)
        return true
      end
      for slot = 1, 6 do
        if not teamMember(slot) then
          send('team.assign', { bagSlot = member.bagSlot, teamSlot = slot, open = 'team' })
          state.selectedBagSlot = nil
          return true
        end
      end
      showFeedback('O time ja possui seis Pokemon.', false)
      return true
    end
    card.onDrop = function(_, draggedWidget)
      return dropTeamMemberIntoBag(card, draggedWidget)
    end
  end
end

teamMember = function(slot)
  local value = state.team[slot]
  if value == false then return nil end
  return value
end

local function renderTeam()
  if not teamSlots then return end
  clearChildren(teamSlots)

  -- Simple glass grid: 2 columns x 3 rows.
  -- Width: 2 * 350 + 12 = 712. Height: 3 * 94 + 2 * 8 = 298.
  local slotWidth = 350
  local slotHeight = 94
  local slotGap = 12
  local slotStepX = slotWidth + slotGap
  local slotStepY = slotHeight + 8

  for slot = 1, 6 do
    local member = teamMember(slot)
    local isActive = member and state.activeInstanceId == member.instanceId or false
    local button = g_ui.createWidget('PokemonTeamSlot', teamSlots)
    button:setId('pokemonTeamSlot' .. slot)
    button:setText('')
    button:setChecked(isActive)
    if member then
      local _, _, genderName = genderPresentation(member.gender)
      button:setTooltip(string.format(
        '%s | Lv.%d | %s | Nature: %s\nClique: summonar/retornar. Desbloqueado: arraste para a Capture Bag ou use o botao direito para remover.',
        member.name or 'Pokemon',
        tonumber(member.level) or 0,
        genderName,
        displayNature(member.nature)
      ))
    else
      button:setTooltip('Desbloqueie, selecione um Pokemon na Capture Bag e clique aqui, ou arraste-o para este slot.')
    end
    button.pokemonTeamSlot = member and slot or nil
    button:setDraggable(member ~= nil and not teamLocked)
    enableRosterDrag(button)
    button:addAnchor(AnchorTop, 'parent', AnchorTop)
    button:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    local column = (slot - 1) % 2
    local row = math.floor((slot - 1) / 2)
    button:setSize({ width = slotWidth, height = slotHeight })
    button:setMarginLeft(column * slotStepX)
    button:setMarginTop(row * slotStepY)

    local slotBadge = g_ui.createWidget('Label', button)
    slotBadge:setId('slotBadge')
    slotBadge:setText(string.format('%02d', slot))
    slotBadge:setSize({ width = 22, height = 14 })
    slotBadge:addAnchor(AnchorTop, 'parent', AnchorTop)
    slotBadge:addAnchor(AnchorRight, 'parent', AnchorRight)
    slotBadge:setMarginTop(4)
    slotBadge:setMarginRight(4)
    slotBadge:setColor('#c0c0c0')
    slotBadge:setFont('verdana-11px-monochrome')
    slotBadge:setTextAlign(AlignCenter)
    slotBadge:setPhantom(true)

    if member then
      local portrait = g_ui.createWidget('UICreature', button)
      portrait:setId('portrait')
      portrait:setSize({ width = 78, height = 78 })
      portrait:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      portrait:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      portrait:setMarginLeft(8)
      portrait:setPhantom(true)
      setCreature(portrait, member.lookType, 64)

      local nameLabel = g_ui.createWidget('Label', button)
      nameLabel:setId('name')
      nameLabel:setText(string.upper(member.name or 'POKEMON'))
      nameLabel:setSize({ width = 195, height = 15 })
      nameLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
      nameLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      nameLabel:setMarginTop(8)
      nameLabel:setMarginLeft(96)
      nameLabel:setColor(isActive and '#8eeaff' or '#eef6fa')
      nameLabel:setFont('verdana-11px-antialised')
      nameLabel:setPhantom(true)

      local _, _, genderName, genderIcon = genderPresentation(member.gender)
      local genderLabel = g_ui.createWidget('PokemonGenderSymbol', button)
      genderLabel:setId('gender')
      genderLabel:setImageSource(genderIcon)
      genderLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
      genderLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
      genderLabel:setMarginTop(4)
      genderLabel:setMarginRight(29)
      genderLabel:setTooltip(genderName)

      local metaLabel = g_ui.createWidget('Label', button)
      metaLabel:setId('meta')
      metaLabel:setText(string.format(
        'LV. %d   NATURE: %s',
        tonumber(member.level) or 0,
        string.upper(displayNature(member.nature))
      ))
      metaLabel:setSize({ width = 226, height = 14 })
      metaLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
      metaLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      metaLabel:setMarginTop(27)
      metaLabel:setMarginLeft(96)
      metaLabel:setColor('#b8c7ce')
      metaLabel:setFont('verdana-11px-monochrome')
      metaLabel:setPhantom(true)

      local hpMaximum = math.max(tonumber(member.maxHp) or 0, 0)
      local hpCurrent = math.max(tonumber(member.currentHp) or hpMaximum, 0)
      local hpPercent = hpMaximum > 0 and math.floor((hpCurrent * 100) / hpMaximum) or 0
      hpPercent = math.max(0, math.min(100, hpPercent))

      local health = g_ui.createWidget('PokemonTeamHpBar', button)
      health:setId('health')
      health:setSize({ width = 226, height = 7 })
      health:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      health:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      health:setMarginLeft(96)
      health:setMarginBottom(23)
      health:setPercent(hpPercent)
      health:setPhantom(true)

      local healthText = g_ui.createWidget('Label', button)
      healthText:setId('healthText')
      healthText:setText(hpMaximum > 0 and string.format('%d / %d', hpCurrent, hpMaximum) or 'HP -- / --')
      healthText:setSize({ width = 226, height = 14 })
      healthText:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      healthText:addAnchor(AnchorBottom, 'parent', AnchorBottom)
      healthText:setMarginLeft(96)
      healthText:setMarginBottom(5)
      healthText:setColor('#d9e1e5')
      healthText:setFont('verdana-11px-monochrome')
      healthText:setTextAlign(AlignCenter)
      healthText:setPhantom(true)
    else
      local emptyLabel = g_ui.createWidget('Label', button)
      emptyLabel:setId('empty')
      emptyLabel:setText('SLOT VAZIO')
      emptyLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
      emptyLabel:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      emptyLabel:setColor('#777777')
      emptyLabel:setFont('verdana-11px-monochrome')
      emptyLabel:setTextAutoResize(true)
      emptyLabel:setPhantom(true)
    end

    button.onClick = function()
      if state.selectedBagSlot then
        if teamLocked then
          showFeedback('Clique em LOCKED para liberar a edicao do time.', false)
          return
        end
        send('team.assign', { bagSlot = state.selectedBagSlot, teamSlot = slot, open = 'team' })
        state.selectedBagSlot = nil
      elseif member then
        send('team.summon', { teamSlot = slot, open = 'team' })
      end
    end
    button.onDrop = function(_, draggedWidget)
      local bagSlot = draggedWidget and draggedWidget.pokemonBagSlot
      if bagSlot then
        if teamLocked then
          showFeedback('Desbloqueie o time antes de mover Pokemon.', false)
          return true
        end
        send('team.assign', { bagSlot = bagSlot, teamSlot = slot, open = 'team' })
        state.selectedBagSlot = nil
        return true
      end
      return false
    end
    button.onMouseRelease = function(_, _, mouseButton)
      if mouseButton == MouseRightButton and member then
        if teamLocked then
          showFeedback('Desbloqueie o time antes de remover Pokemon.', false)
          return true
        end
        send('team.remove', { teamSlot = slot, open = 'team' })
        return true
      end
      return false
    end
  end
  renderActive()
end

renderQuickBar = function()
  if not quickBar or not quickBarSlots then return end
  clearChildren(quickBarSlots)

  quickBar:setSize({
    width = quickBarCompact and 66 or 232,
    height = 367,
  })

  local title = quickBar:recursiveGetChildById('quickBarTitle')
  local manager = quickBar:recursiveGetChildById('quickBarManagerButton')
  local mode = quickBar:recursiveGetChildById('quickBarModeButton')
  if title then title:setVisible(not quickBarCompact) end
  if manager then
    manager:setText(quickBarCompact and 'T' or 'Team')
    manager:setSize({ width = quickBarCompact and 18 or 42, height = 18 })
  end
  if mode then
    mode:setText(quickBarCompact and '>' or '<')
    mode:setSize({ width = 20, height = 18 })
  end

  for slot = 1, 6 do
    local member = teamMember(slot)
    local style = quickBarCompact and 'PokemonQuickCompactSlot' or 'PokemonQuickTeamSlot'
    local button = g_ui.createWidget(style, quickBarSlots)
    local isActive = member and state.activeInstanceId == member.instanceId or false
    local currentHp = member and math.max(tonumber(member.currentHp) or 0, 0) or 0
    local maximumHp = member and math.max(tonumber(member.maxHp) or 0, 0) or 0
    if isActive and state.activeCreatureId then
      local activeCreature = g_map.getCreatureById(state.activeCreatureId)
      if activeCreature and maximumHp > 0 then
        local runtimePercent = math.max(0, math.min(100, activeCreature:getHealthPercent()))
        currentHp = math.floor((maximumHp * runtimePercent) / 100)
        member.currentHp = currentHp
      end
    end
    local fainted = member and maximumHp > 0 and currentHp <= 0 or false
    local percent = maximumHp > 0 and math.floor((currentHp * 100) / maximumHp) or 0
    percent = math.max(0, math.min(100, percent))

    button:setId('pokemonQuickSlot' .. slot)
    button:addAnchor(AnchorTop, 'parent', AnchorTop)
    button:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    button:setMarginTop((slot - 1) * 57)
    button:setMarginLeft(quickBarCompact and 4 or 3)
    button:setChecked(isActive)
    button:setEnabled(not fainted)
    button.pokemonTeamSlot = member and slot or nil

    if member then
      local portrait = g_ui.createWidget('UICreature', button)
      portrait:setId('portrait')
      portrait:setSize({
        width = quickBarCompact and 42 or 48,
        height = quickBarCompact and 42 or 48,
      })
      portrait:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      portrait:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      portrait:setMarginLeft(quickBarCompact and 5 or 5)
      portrait:setPhantom(true)
      setCreature(portrait, member.lookType, quickBarCompact and 36 or 40)

      local slotNumber = g_ui.createWidget('Label', button)
      slotNumber:setText(tostring(slot))
      slotNumber:setSize({ width = 18, height = 16 })
      slotNumber:addAnchor(AnchorTop, 'parent', AnchorTop)
      slotNumber:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      slotNumber:setMarginTop(4)
      slotNumber:setMarginLeft(4)
      slotNumber:setColor('#c0c0c0')
      slotNumber:setFont('verdana-11px-monochrome')
      slotNumber:setTextAlign(AlignCenter)
      slotNumber:setPhantom(true)

      if not quickBarCompact then
        local name = g_ui.createWidget('Label', button)
        name:setText(string.upper(member.name or 'POKEMON'))
        name:setSize({ width = 130, height = 15 })
        name:addAnchor(AnchorTop, 'parent', AnchorTop)
        name:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        name:setMarginTop(5)
        name:setMarginLeft(60)
        name:setColor(isActive and '#9fda6d' or '#dfdfdf')
        name:setFont('verdana-11px-antialised')
        name:setPhantom(true)

        local _, _, genderName, genderIcon = genderPresentation(member.gender)
        local gender = g_ui.createWidget('PokemonGenderSymbol', button)
        gender:setImageSource(genderIcon)
        gender:addAnchor(AnchorTop, 'parent', AnchorTop)
        gender:addAnchor(AnchorRight, 'parent', AnchorRight)
        gender:setMarginTop(0)
        gender:setMarginRight(5)
        gender:setTooltip(genderName)

        local meta = g_ui.createWidget('Label', button)
        meta:setText(string.format(
          'LV.%d  %s',
          tonumber(member.level) or 0,
          displayNature(member.nature)
        ))
        meta:setSize({ width = 150, height = 14 })
        meta:addAnchor(AnchorTop, 'parent', AnchorTop)
        meta:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        meta:setMarginTop(20)
        meta:setMarginLeft(60)
        meta:setColor('#a8a8a8')
        meta:setFont('verdana-11px-monochrome')
        meta:setPhantom(true)

        local health = g_ui.createWidget('PokemonQuickHpBar', button)
        health:setSize({ width = 112, height = 7 })
        health:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        health:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        health:setMarginLeft(60)
        health:setMarginBottom(7)
        health:setPercent(percent)
        health:setPhantom(true)

        local healthText = g_ui.createWidget('Label', button)
        healthText:setText(string.format('%d%%', percent))
        healthText:setSize({ width = 38, height = 14 })
        healthText:addAnchor(AnchorRight, 'parent', AnchorRight)
        healthText:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        healthText:setMarginRight(6)
        healthText:setMarginBottom(4)
        healthText:setColor(percent < 35 and '#ff6666' or '#c0c0c0')
        healthText:setFont('verdana-11px-monochrome')
        healthText:setTextAlign(AlignRight)
        healthText:setPhantom(true)
      end

      button:setTooltip(string.format(
        '%s | Lv.%d | %s | Nature: %s | HP %d/%d%s',
        member.name or 'Pokemon',
        tonumber(member.level) or 0,
        select(3, genderPresentation(member.gender)),
        displayNature(member.nature),
        currentHp,
        maximumHp,
        isActive and ' | EM CAMPO' or ''
      ))
      button.onClick = function()
        if fainted then return true end
        send('team.summon', { teamSlot = slot, open = false })
        return true
      end
    else
      local empty = g_ui.createWidget('Label', button)
      empty:setText(quickBarCompact and tostring(slot) or string.format('%02d  SLOT VAZIO', slot))
      empty:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
      empty:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
      empty:setColor('#777777')
      empty:setFont('verdana-11px-monochrome')
      empty:setTextAutoResize(true)
      empty:setPhantom(true)
      button:setTooltip(string.format('Slot %d vazio', slot))
    end
  end
end

renderActive = function(healthPercent)
  if not activeName then return end
  local active
  local activeSlot
  for slot = 1, 6 do
    local member = teamMember(slot)
    if member and member.instanceId == state.activeInstanceId then
      active = member
      activeSlot = slot
      break
    end
  end

  if not active then
    activePortrait:setVisible(false)
    activeName:setText('NENHUM POKEMON EM CAMPO')
    activeDescription:setText('Escolha um slot abaixo para liberar um Pokemon.')
    activeHealth:setPercent(0)
    activeHealthText:setText('HP -- / --')
    if activeActionButton then
      activeActionButton:setText('Selecione')
      activeActionButton:setEnabled(false)
      activeActionButton.activeTeamSlot = nil
    end
    return
  end

  activePortrait:setVisible(true)
  setCreature(activePortrait, active.lookType, 128)
  activeName:setText(string.format('%s  LV. %d', string.upper(active.name or 'POKEMON'), tonumber(active.level) or 0))
  activeDescription:setText(string.format(
    '%s  |  Nature: %s  |  ACTIVE',
    select(1, genderPresentation(active.gender)),
    displayNature(active.nature)
  ))
  local maximum = math.max(tonumber(active.maxHp) or 0, 0)
  local current = math.max(tonumber(active.currentHp) or 0, 0)
  if not healthPercent and state.activeCreatureId then
    local activeCreature = g_map.getCreatureById(state.activeCreatureId)
    if activeCreature then
      healthPercent = activeCreature:getHealthPercent()
    end
  end
  local percent = healthPercent or (maximum > 0 and math.floor((current * 100) / maximum) or 0)
  percent = math.max(0, math.min(100, percent))
  if healthPercent and maximum > 0 then
    current = math.floor((maximum * percent) / 100)
    active.currentHp = current
  end
  activeHealth:setPercent(percent)
  activeHealthText:setText(string.format('HP %d / %d  (%d%%)', current, maximum, percent))
  if activeActionButton then
    activeActionButton:setText('Recolher')
    activeActionButton:setEnabled(true)
    activeActionButton.activeTeamSlot = activeSlot
  end
end

local function activeMember()
  for slot = 1, 6 do
    local member = teamMember(slot)
    if member and member.instanceId == state.activeInstanceId then return member end
  end
  return nil
end

renderPokeInfo = function()
  if not pokeInfoBar then return end
  local member = activeMember()
  local title = pokeInfoBar:recursiveGetChildById('pokeInfoTitle')
  local details = pokeInfoBar:recursiveGetChildById('pokeInfoDetails')
  local hp = pokeInfoBar:recursiveGetChildById('pokeInfoHp')
  local hpText = pokeInfoBar:recursiveGetChildById('pokeInfoHpText')
  local xp = pokeInfoBar:recursiveGetChildById('pokeInfoXp')
  local xpText = pokeInfoBar:recursiveGetChildById('pokeInfoXpText')
  if not member then
    title:setText('POKE INFO')
    details:setText('Nenhum Pokemon em campo')
    hp:setPercent(0); hpText:setText('HP -- / --')
    xp:setPercent(0); xpText:setText('EXP --')
    return
  end
  local maximumHp = math.max(tonumber(member.maxHp) or 0, 1)
  local currentHp = math.max(0, tonumber(member.currentHp) or 0)
  if state.activeCreatureId then
    local creature = g_map.getCreatureById(state.activeCreatureId)
    if creature then currentHp = math.floor(maximumHp * creature:getHealthPercent() / 100) end
  end
  local experience = math.max(0, tonumber(member.experience) or 0)
  local startXp = math.max(0, tonumber(member.experienceLevelStart) or 0)
  local nextXp = math.max(startXp, tonumber(member.experienceLevelNext) or startXp)
  local xpPercent = nextXp > startXp and math.floor((experience - startXp) * 100 / (nextXp - startXp)) or 100
  xpPercent = math.max(0, math.min(100, xpPercent))
  title:setText(string.format('%s  LV.%d', string.upper(member.name or 'POKEMON'), tonumber(member.level) or 1))
  details:setText(string.format('%s  |  NATURE: %s', select(3, genderPresentation(member.gender)), string.upper(displayNature(member.nature))))
  hp:setPercent(math.max(0, math.min(100, math.floor(currentHp * 100 / maximumHp))))
  hpText:setText(string.format('HP %d / %d', currentHp, maximumHp))
  xp:setPercent(xpPercent)
  xpText:setText(nextXp > startXp and string.format('EXP %d / %d', experience - startXp, nextXp - startXp) or 'EXP MAX')
end

renderMoves = function()
  if not moveSlots then return end
  clearChildren(moveSlots)
  for index, move in ipairs(state.moves or {}) do
    local button = g_ui.createWidget('PokemonMoveSlot', moveSlots)
    button:setId('pokemonMove' .. tostring(move.id))
    local availableAt = tonumber(move.availableAt) or 0
    local remaining = math.max(0, availableAt - (tonumber(state.serverTime) or 0))
    local pending = state.pendingMoves[move.id] == true
    button:setEnabled(not pending and remaining <= 0 and state.activeInstanceId ~= false)
    local typeBadge = g_ui.createWidget('Label', button)
    typeBadge:setText(string.upper(tostring(move.type or '?'):sub(1, 1)))
    typeBadge:setSize({ width = 20, height = 20 })
    typeBadge:addAnchor(AnchorLeft, 'parent', AnchorLeft); typeBadge:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    typeBadge:setMarginLeft(4); typeBadge:setColor('#8eeaff'); typeBadge:setFont('verdana-11px-antialised'); typeBadge:setTextAlign(AlignCenter); typeBadge:setPhantom(true)
    local name = g_ui.createWidget('Label', button)
    name:setText(string.upper(move.name or move.id or 'MOVE'))
    name:setSize({ width = 96, height = 14 }); name:addAnchor(AnchorTop, 'parent', AnchorTop); name:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    name:setMarginLeft(27); name:setMarginTop(5); name:setFont('verdana-11px-monochrome'); name:setColor('#e9f5ff'); name:setPhantom(true)
    local cooldown = g_ui.createWidget('Label', button)
    cooldown:setText(pending and 'CASTING' or (remaining > 0 and string.format('%ds', remaining) or 'READY'))
    cooldown:setSize({ width = 96, height = 14 }); cooldown:addAnchor(AnchorBottom, 'parent', AnchorBottom); cooldown:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    cooldown:setMarginLeft(27); cooldown:setMarginBottom(4); cooldown:setFont('verdana-11px-monochrome'); cooldown:setColor((pending or remaining > 0) and '#ffb466' or '#71df88'); cooldown:setPhantom(true)
    button:setTooltip(string.format('%s | %s | %s | cooldown %0.1fs%s', move.name or move.id, tostring(move.type), tostring(move.category), (tonumber(move.cooldown) or 0) / 1000, move.targetMode == 'self' and ' | self' or ' | target'))
    button.onClick = function()
      if pending or remaining > 0 then return true end
      state.pendingMoves[move.id] = true
      renderMoves()
      send('move.cast', { moveId = move.id, open = false })
      return true
    end
  end
end

local function onActiveHealthChange(creature, healthPercent)
  if state.activeCreatureId and creature:getId() == state.activeCreatureId then
    renderActive(healthPercent)
    renderQuickBar()
    renderPokeInfo()
  end
end

local function updateLockVisual()
  if not lockButton then return end
  lockButton:setText(teamLocked and 'Lock' or 'Edit')
  lockButton:setChecked(teamLocked)
  lockButton:setColor(teamLocked and '#e0c070' or '#9fda6d')
  lockButton:setTooltip(teamLocked and 'Time protegido. Clique para desbloquear movimentos.' or 'Time desbloqueado. Arrastar e remover estao liberados.')
end

dropTeamMemberIntoBag = function(_, draggedWidget)
  local teamSlot = draggedWidget and draggedWidget.pokemonTeamSlot
  if not teamSlot then return false end
  if teamLocked then
    showFeedback('Desbloqueie o time antes de devolver Pokemon para a Capture Bag.', false)
    return true
  end
  send('team.remove', { teamSlot = teamSlot, open = 'bag' })
  return true
end

showFeedback = function(message, success)
  if not bagWindow then return end
  local label = bagWindow:recursiveGetChildById('feedback')
  label:setText(message or '')
  label:setColor(success == false and '#ff6478' or '#70e879')
end

local function applySnapshot(data)
  state.revision = tonumber(data.revision) or 0
  state.capacity = tonumber(data.capacity) or 20
  state.team = type(data.team) == 'table' and data.team or {}
  local teamInstances = {}
  for slot = 1, 6 do
    local member = state.team[slot]
    if member and member.instanceId then
      teamInstances[tostring(member.instanceId)] = true
    end
  end
  state.bag = {}
  if type(data.bag) == 'table' then
    for _, member in ipairs(data.bag) do
      if not teamInstances[tostring(member.instanceId)] then
        state.bag[#state.bag + 1] = member
      else
        g_logger.warning(string.format('[PokemonRoster] Ignored duplicated instance %s in Capture Bag snapshot', tostring(member.instanceId)))
      end
    end
  end
  state.activeInstanceId = data.activeInstanceId or false
  state.activeCreatureId = tonumber(data.activeCreatureId) or false
  state.moves = type(data.moves) == 'table' and data.moves or {}
  state.serverTime = tonumber(data.serverTime) or 0
  -- A server snapshot is the acknowledgement for every cast, successful or
  -- rejected. It replaces temporary client-side request locks.
  state.pendingMoves = {}
  updateBattleHudVisibility()
  if syncStatus then
    syncStatus:setText(string.format('Sincronizado | rev %d', state.revision))
  end
  renderBag()
  renderTeam()
  renderQuickBar()
  renderPokeInfo()
  renderMoves()
  showFeedback(data.message, data.success)
  if data.open == 'bag' then
    revealBag()
  elseif data.open == 'team' then
    revealTeam()
  end
end

local function onRosterOpcode(_, opcode, payload)
  if opcode ~= OPCODE then return end
  if type(payload) ~= 'table' or payload.version ~= VERSION then
    g_logger.error('[PokemonRoster] Invalid protocol payload')
    return
  end
  if payload.action == 'roster.snapshot' and type(payload.data) == 'table' then
    applySnapshot(payload.data)
  elseif payload.action == 'roster.error' and type(payload.data) == 'table' then
    local message = tostring(payload.data.message or 'Capture Bag synchronization failed.')
    g_logger.error('[PokemonRoster] ' .. message)
    showFeedback(message, false)
  end
end

function pokemonRosterController:onInit()
  self:registerExtendedJSONOpcode(OPCODE, onRosterOpcode)
  connect(Creature, { onHealthPercentChange = onActiveHealthChange })
end

function pokemonRosterController:onTerminate()
  disconnect(Creature, { onHealthPercentChange = onActiveHealthChange })
end

function pokemonRosterController:onGameStart()
  self:loadUI('pokemon_roster')
  bagWindow = self.ui:recursiveGetChildById('captureBagWindow')
  teamWindow = self.ui:recursiveGetChildById('teamWindow')
  quickBar = self.ui:recursiveGetChildById('pokemonQuickBar')
  quickBarSlots = self.ui:recursiveGetChildById('quickBarSlots')
  bagList = self.ui:recursiveGetChildById('bagList')
  teamSlots = self.ui:recursiveGetChildById('teamSlots')
  topActionBar = self.ui:recursiveGetChildById('pokemonTopActionBar')
  rosterButton = self.ui:recursiveGetChildById('pokemonRosterButton')
  lockButton = self.ui:recursiveGetChildById('teamLockButton')
  activePortrait = self.ui:recursiveGetChildById('activePortrait')
  activeName = self.ui:recursiveGetChildById('activeName')
  activeDescription = self.ui:recursiveGetChildById('activeDescription')
  activeHealth = self.ui:recursiveGetChildById('activeHealth')
  activeHealthText = self.ui:recursiveGetChildById('activeHealthText')
  activeActionButton = self.ui:recursiveGetChildById('activeActionButton')
  syncStatus = self.ui:recursiveGetChildById('syncStatus')
  pokeInfoBar = self.ui:recursiveGetChildById('pokemonInfoBar')
  moveBar = self.ui:recursiveGetChildById('pokemonMoveBar')
  moveSlots = self.ui:recursiveGetChildById('pokemonMoveSlots')
  teamLocked = g_settings.getBoolean('pokemonTeamLocked', true)
  quickBarCompact = g_settings.getBoolean('pokemonQuickBarCompact', false)
  bagList.onDrop = dropTeamMemberIntoBag
  bagWindow.onDrop = dropTeamMemberIntoBag
  updateLockVisual()
  renderQuickBar()
  setupQuickBarDrag()
  teamWindow:hide()
  quickBar:show()
  pokeInfoBar:hide()
  moveBar:hide()
  topActionBar:show()
  topActionBar:raise()
  self:scheduleEvent(function()
    send('roster.request', { open = false })
  end, 500, 'pokemonRosterInitialSync')
  self:cycleEvent(function()
    if state.serverTime > 0 then state.serverTime = state.serverTime + 1; renderMoves() end
  end, 1000, 'pokemonRosterCooldownTicker')
end

function pokemonRosterController:onGameEnd()
  if topActionBar then topActionBar:hide() end
  rosterButton = nil
  topActionBar = nil
  state = {
    revision = 0,
    capacity = 20,
    bag = {},
    team = {},
    activeInstanceId = false,
    activeCreatureId = false,
    moves = {},
    serverTime = 0,
    pendingMoves = {},
    selectedBagSlot = nil,
  }
  if bagWindow then bagWindow:hide() end
  if teamWindow then teamWindow:hide() end
  if quickBar then quickBar:hide() end
  if pokeInfoBar then pokeInfoBar:hide() end
  if moveBar then moveBar:hide() end
  bagWindow, teamWindow, quickBar, quickBarSlots, bagList, teamSlots, lockButton = nil, nil, nil, nil, nil, nil, nil
  pokeInfoBar, moveBar, moveSlots = nil, nil, nil
  activePortrait, activeName, activeDescription, activeHealth, activeHealthText = nil, nil, nil, nil, nil
  activeActionButton, syncStatus = nil, nil
end

function showBag()
  if bagWindow then
    revealBag()
    send('roster.request', { open = 'bag' })
  end
end

function hideBag()
  if bagWindow then bagWindow:hide() end
end

function showTeam()
  if teamWindow then
    revealTeam()
    send('roster.request', { open = 'team' })
  end
end

function hideTeam()
  if teamWindow then teamWindow:hide() end
  if rosterButton then rosterButton:setOn(false) end
end

-- Public synchronization hook for authoritative server-side systems such as
-- Nurse Joy. It refreshes data without opening or moving roster windows.
function refresh(openView)
  if not g_game.isOnline() then return false end
  send('roster.request', { open = openView or false })
  return true
end

function toggleTeam()
  if teamWindow and teamWindow:isVisible() then hideTeam() else showTeam() end
end

function toggleQuickBarMode()
  quickBarCompact = not quickBarCompact
  g_settings.set('pokemonQuickBarCompact', quickBarCompact)
  renderQuickBar()
end

function toggleTeamLock()
  teamLocked = not teamLocked
  g_settings.set('pokemonTeamLocked', teamLocked)
  updateLockVisual()
  renderBag()
  renderTeam()
end

function toggleActivePokemon()
  if not activeActionButton or not activeActionButton.activeTeamSlot then
    return
  end
  send('team.summon', { teamSlot = activeActionButton.activeTeamSlot, open = 'team' })
end
