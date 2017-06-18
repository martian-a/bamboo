--------------
-- Organise --
--------------

--[[
  Move and/or flag messages by subject.
]]--

print(" \n\n== Organising ==\n")


function organise(group)

  print("\n")

  -- Validation
  if (group == nil) then
    print("! Error: group not specified.")
    return
  elseif (group.consolidate == nil or group.consolidate.destination ==  nil) then
    print("! Error: account not specified.")
    return
  elseif (group.addresses == nil) then
    print("! Error: no addresses specified.")
    return
  elseif (group.subjects == nil) then
    print("! Error: subjects not specified.")
    return
  end
  
  -- Get the account to be organised
  local account = group.consolidate.destination
  print("Organising " .. group.name .. " in " .. account.name .. ".")
  
  -- Select all messages in the inbox of the account to be organised
  local all_messages = account.INBOX:select_all()
  print(#all_messages .. " messages to check.")
  
  -- Get email addresses of group
  local addresses = group.addresses
  print(#addresses .. " addresses to check.")
  
  
  local function select_by_address(messages, address)
  
    print("- checking " .. address)
    local matches = messages:contain_from(address)
    print("...found " .. #matches .. " messages.")
  
    return matches
  end
  
 
  
  --[[
    The rules to apply to any matches.
  ]]--
  local function apply_rules(account, group, messages)
  
    if (#messages > 0) then
    
      for _, subject in ipairs(group.subjects) do
        
        local unmatched = messages
        local all_matches = {}
        for _, keyword in ipairs(subject.keywords) do
          local matches = unmatched:contain_subject(keyword)
          all_matches = all_matches + matches
          unmatched = unmatched - matches
        end
        
        if (#all_matches > 0) then
          
          if (not (subject.folder == nil)) then
            all_matches:move(account[subject.folder])
          end
          
          if (not (subject.starred == nil) and subject.starred == true) then
            flag_messages(account, messages)
          end
        
        else
          print("0 " .. subject.name)
        end
        
      end
    
    else
      print("0 messages to organise.")
    end
  
  end

  --[[
    Select messages from email addresses in group
    and apply rules.
  ]]--
  local unmatched = all_messages
  local all_matches = {}
  if (#all_messages > 1000) then
    --[[ 
      More than 1000 messages to check.
      Apply rules after each address checked.
    ]]--
    
    for _, address in ipairs(addresses) do
      local matches = select_by_address(unmatched, address)
      apply_rules(account, group, matches)
      
      all_matches = all_matches + matches
      unmatched = unmatched - matches
    end

  else
    --[[
      Fewer than 1000 messages to check.
      Collect together all messages from all addresses
      before applying rules.
    ]]--
    
    for _, address in ipairs(addresses) do
      local matches = select_by_address(unmatched, address)
      all_matches = all_matches + matches
      unmatched = unmatched - matches
    end
    
    apply_rules(account, group, all_matches)
    
  end
  
  
    
end
