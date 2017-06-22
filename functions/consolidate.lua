--------------------------
-- Consolidate Messages --
--------------------------

--[[
  Move non-personal messages to catchall.
  Flag messages from priority senders.
]]--
function consolidate(accounts)

  announce("Consolidating")

  local function consolidate_group(account, group) 
  
    print("\n")
    
    -- Validation
    if (account == nil) then
      print("! Error: account not specified.")
      return
    elseif (group == nil) then
      print("! Error: group not specified.")
      return
    elseif (group.addresses == nil) then
      print("! Error: no addresses specified.")
      return
    elseif (group.consolidate == nil or group.consolidate.destination == nil) then
      print("! Error: destination account not specified.")
      return
    end
    
    print("Consolidating " .. group.name .. " in " .. account.name .. ".")
    
    -- Select all messages in the inbox of the account to be organised
    local all_messages = account.INBOX:select_all()
    print(#all_messages .. " messages to check.")
    
    -- Get email addresses of group
    local addresses = get_group_addresses(group)
    print(#addresses .. " addresses to check.")
      
    
    
    local function select_by_address(messages, address)
    
      print("- checking " .. address)
      local matches = 
            messages:contain_from(address)
          + messages:contain_cc(address)
          + messages:contain_bcc(address)
          + messages:contain_to(address)
      print("...found " .. #matches .. " messages.")
    
      return matches
    end  
      
    
    --[[
      The rules to apply to any matches.
    ]]--
    local function apply_rules(account, group, messages)
    
      if (#messages > 0) then
      
        if (group.consolidate.star == nil or group.consolidate.star == false) then
          -- don't flag messages
        elseif (not(group.consolidate.star == true)) then
          print("! Error: the value of consolidate.star must be either true or false")
        else
          flag_messages(account, messages)
        end
          
        -- Move messages related to family to my personal account
        messages:move_messages(group.consolidate.destination["INBOX"])
      else
        print("0 messages to move.")
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
      
      for index, address in ipairs(addresses) do
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
      
      for index, address in ipairs(addresses) do
        local matches = select_by_address(unmatched, address)
        all_matches = all_matches + matches
        unmatched = unmatched - matches
      end
      
      apply_rules(account, group, all_matches)
      
    end
   
  end  


  --[[
    Work out which groups require consolidation
    and in which order and carry it out.
  ]]--
  for order = 1, size(contacts) do
    
      for _, group in pairs(contacts) do
           
        if (group.consolidate.order == order and not(group.consolidate.skip)) then
        
          for _, source in ipairs(group.consolidate.check) do
            consolidate_group(source, group)
          end
          
        end
      
      end
    
  end
  
end
