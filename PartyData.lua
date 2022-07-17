_addon.name = 'PartyData'
_addon.author = 'Eit'
_addon.version = '0.0'
_addon.command = 'pd'

require('chat')
files = require('files')

settings = {}
settings.TimestampFormat = '%Y-%m-%d %H:%M:%S'
settings.WhiteList = S{'Eit','Eitwo','Pipster','Firlei','Andyhara','Melkhior','Beastaru'}

start_time = os.time()


windower.register_event('action', function(act)
  local playerName = windower.ffxi.get_mob_by_id(act.actor_id).name
  
  -- Exits if not part of the white list
  if not settings.WhiteList:contains(playerName) then 
    return 
  end

  -- Create New file if needed, one file will be created per hour
  local date = os.date('*t')
  local file = files.new('../../logs/%s_%.4u.%.2u.%.2u.%.2u.log':format('PartyData', date.year, date.month, date.day, date.hour))
  if not file:exists() then
    file:create()
  end

  -- Get Party Info every 5 seconds and log event
  seconds = os.time() - start_time
  if seconds >= 5 then
    getPartyStats(file)
    start_time = os.time()
  end

  -- Log Melee hits
  if act.category == 1 then processMelee(file, act, playerName) 
  elseif act.category == 3 then processWeaponSkill(file, act, playerName) 
  end

end)


function processMelee(file, act, playerName)
  local hitEffect = {
    [1]='Normal',
    [15]='Miss',
    [67]='Crit',
    [31]='Shadow'
  }

  local hitType = {
    [0]='MainHand',
    [1]='OffHand',
    [2]='LeftKick',
    [3]='RightKick'
  }
  
  for _, target in pairs(act.targets) do
    local values = {}
    values.playerName = playerName
    values.targetName = windower.ffxi.get_mob_by_id(target.id).name
    values.actionCount = target.action_count
    values.currentTime = os.date(settings.TimestampFormat, os.time())
    
    for _, action in pairs(target.actions) do
      values.normalDamage = action.param
      values.enspellDamage = action.add_effect_param
      values.hitEffect = hitEffect[action.message]
      values.hitType = hitType[action.animation]

      -- Write to file
      writeToFile(file, 'meleeEvent', values)
    end
  end
end

function processWeaponSkill(file, act, playerName)
  for _, target in pairs(act.targets) do
    local values = {}
    values.playerName = playerName
    values.targetName = windower.ffxi.get_mob_by_id(target.id).name
    values.weaponSkillId = act.param - 768
    
    for _, action in pairs(target.actions) do
      values.normalDamage = action.param
      values.skillChainDamage = action.add_effect_param

      -- Write to file
      writeToFile(file, 'weaponSkillEvent', values)
    end
  end
end

function getPartyStats(file)
  local party = windower.ffxi.get_party()
  local validSlots = S{'p0','p1','p2','p3','p4','p5'}

  for k,v in pairs(party) do
    local values = {}
    setmetatable(values,{__index=v})
    values.partySize = party.party1_count

    if validSlots:contains(k) then 
      writeToFile(file,'playerInfo',values) 
    end
  end
end

function writeToFile(file, reqType, value)
  local currentTime = os.date(settings.TimestampFormat, os.time())

  if reqType == 'playerInfo' then 
    file:append('{eventType:\'%s\',ts:\'%s\',name:\'%s\',hp:%s,mp:%s,partySize:%s}\n'
      :format(reqType, currentTime, value.name, value.hp, value.mp, value.partySize))

  elseif reqType == 'meleeEvent' then 
    file:append('{eventType:\'%s\',ts:\'%s\',playerName:\'%s\',targetName:\'%s\',regularDamage:%s,enspellDamage:%s,hitType:%s,hitEffect:%s,hitCount:%s}\n'
      :format(reqType, value.currentTime, value.playerName, value.targetName, value.normalDamage, value.enspellDamage, value.hitType, value.hitEffect, value.actionCount))

  elseif reqType == 'weaponSkillEvent' then 
    file:append('{eventType:\'%s\',ts:\'%s\',playerName:\'%s\',targetName:\'%s\',regularDamage:%s,skillChainDamage:%s,weaponSkillId:%s}\n'
      :format(reqType, currentTime, value.playerName, value.targetName, value.normalDamage, value.skillChainDamage, value.weaponSkillId))
  end
end