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

  if settings.WhiteList:contains(playerName)then
    for k,v in pairs(act) do
      -- if k == 'targets' then print(v) end
      if k == 'category' then print(k..':'..tostring(v)) end
      if k == 'param' then print(k..':'..tostring(v)) end --A parameter passed usually to further identify the type of action, such as spell/ability ID.
      if k == 'targets' then 
        for t_k,t_v in pairs(v) do

          -- For each target get actions
          for a_k, a_v in pairs(t_v) do
            -- print(a_k)
            -- if a_k == 'action_count' then print(a_k..':'..tostring(a_v)) end
            -- if a_k == 'id' then print(a_k..':'..tostring(a_v)) end
            if a_k == 'actions' then 
              for act_key, act_val in pairs (a_v) do
                print('action_param:'..act_val.param) --A specific parameter for this action. Typically the damage number or spell ID.
                print('message:'..act_val.message) --A message to be displayed, given certain parameters. Refer to Message IDs for a full reference
                print('addEffect1:'..act_val.add_effect_effect) -- 0 for attacks and abilities that do not have an additional status effect.
                print('addEffect2:'..act_val.add_effect_param) -- Usually the damage dealt by the additional effect, including Skillchain damage for weapon skills.
                -- printTable(act_val)
              end

            end
          end
        end
      end
    end 
  end
end)

function printTable(table)
  for k,v in pairs(table) do
    print(k..':'..tostring(v))
  end
end




windower.register_event('incoming text', function(_, text, _, _, blocked)
  if blocked or text == '' then
      return
  end

  local date = os.date('*t')
  local file = files.new('../../logs/%s_%.4u.%.2u.%.2u.%.2u.log':format('PartyData', date.year, date.month, date.day, date.hour))
  if not file:exists() then
      file:create()
  end

  seconds = os.time() - start_time
  if seconds >= 5 then
    getPartyStats(file)
    start_time = os.time()
  end

  

  -- file:append('%s%s\n':format(settings.AddTimestamp and os.date(settings.TimestampFormat, os.time()) or '', text:strip_format()))
end)

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
  if reqType == 'playerInfo' then file:append('{eventType:\''..reqType..',ts:\''..os.date(settings.TimestampFormat, os.time())..'\',name:\''..value.name..'\',hp:'..tostring(value.hp)..',mp:'..tostring(value.mp)..'}\n') 
  elseif reqType == 'partyCount' then file:append('{eventType:\''..reqType..',ts:\''..os.date(settings.TimestampFormat, os.time())..'\',partySize:'..tostring(value)..'}\n') 
  end
end