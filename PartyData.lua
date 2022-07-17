_addon.name = 'PartyData'
_addon.author = 'Eit'
_addon.version = '0.0'
_addon.command = 'pd'

require('chat')
files = require('files')

settings = {}
settings.TimestampFormat = '%Y-%m-%d %H:%M:%S'
settings.WhiteList = S{'Eit','Eitwo'}

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
  if act.category == 1 then 
    processMelee(file, act, playerName) 
  end

end)


function processMelee(file, act, playerName)
  local hitType = {
    [1]='Normal',
    [15]='Miss',
    [67]='Crit'
  }
  
  local values = {}
  for _, target in pairs(act.targets) do
    values.targetName = windower.ffxi.get_mob_by_id(target.id).name
    values.actionCount = target.action_count
    
    for _, action in pairs(target.actions) do
      values.normalDamage = action.param
      values.enspellDamage = action.add_effect_param
      values.hitType = hitType[action.message] -- 1=Normal, 15=Miss, 67=Crit


      writeToFile(file, 'meleeEvent', values)
    end
  end
end

function getPartyStats(file)
  local party = windower.ffxi.get_party()

  for k,v in pairs(party) do
    if k == 'p0' then writeToFile(file,'playerInfo',v) 
    elseif k == 'p1' then writeToFile(file,'playerInfo',v) 
    elseif k == 'p2' then writeToFile(file,'playerInfo',v) 
    elseif k == 'p3' then writeToFile(file,'playerInfo',v) 
    elseif k == 'p4' then writeToFile(file,'playerInfo',v) 
    elseif k == 'p5' then writeToFile(file,'playerInfo',v) 
    elseif k == 'party1_count' then writeToFile(file,'partyCount',v) 
    end
  end
end

function writeToFile(file, reqType, value)
  print(reqType)
  local currentTime = os.date(settings.TimestampFormat, os.time())
  if reqType == 'playerInfo' then file:append('{eventType:\''..reqType..',ts:\''..currentTime..'\',name:\''..value.name..'\',hp:'..tostring(value.hp)..',mp:'..tostring(value.mp)..'}\n') 
  elseif reqType == 'partyCount' then file:append('{eventType:\''..reqType..',ts:\''..currentTime..'\',partySize:'..tostring(value)..'}\n') 
  elseif reqType == 'meleeEvent' then 
    
    file:append('{eventType:\'%s\',ts:\'%s\',targetName:\'%s\',regularDamage:%s,enspellDamage:%s,hitType:%s,hitCount:%s}\n':format(reqType,currentTime,value.targetName,value.normalDamage,value.enspellDamage,value.hitType,value.actionCount))
  end
end