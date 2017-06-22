--------------
-- Organise --
--------------

--[[
  Move and/or flag messages by subject.
  ]]--
function organise(account)

  announce("Organising")
  
  
  local function organise_group(group)
  
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
    elseif (group.filters == nil) then
      print("! Error: filters not specified.")
      return
    end
  
    -- Get the account to be organised
    local account = group.consolidate.destination
    print("Organising " .. group.name .. " in " .. account.name .. ".")
  
    -- Select all messages in the inbox of the account to be organised
    local all_messages = account.INBOX:select_all()
    print(#all_messages .. " message(s) to check.")
  
    -- Get all filters for group
    local all_filters = group.filters
    print(#all_filters .. " filter(s) to apply.")
  
  
    local function select_by_address(messages, address)
  
      print("- checking " .. address)
      local matches = messages:contain_from(address)
      print("...found " .. #matches .. " message(s).")
  
      return matches
    end
  
  
  
    --[[
      The rules to apply to any matches.
    ]]--
    local function apply_rules(account, group, filter, messages)
  
      if (#messages > 0) then
  
        local all_matches = {}
        if (filter.keywords) then
  
          local unmatched = messages
          for _, keyword in ipairs(filter.keywords) do
  
            local matches = unmatched:contain_subject(keyword)
            all_matches = all_matches + matches
            unmatched = unmatched - matches
  
          end
        else
          all_matches = messages
        end
  
  
        if (#all_matches > 0) then
  
          -- Flag unread matches       
          if (filter.star == true) then
            
            local unread = all_matches:is_unseen()
            flag_messages(account, unread)
                 
          end
          
          
          if (filter.folder) then
  
            -- Get all flagged messages (new and old)
            local unflagged = all_matches - all_matches:is_flagged()
            
            -- Move them to the folder specified in address book
            unflagged:move_messages(account[filter.folder])
  
          end
  
        else
          print("No filter rules apply.")
        end
  
  
      else
        print("0 messages to organise.")
      end
  
    end
  
  
  
    -- Loop through filters
    for _, filter in ipairs(all_filters) do
  
      if (filter.name) then
        print("Applying filter: " .. filter.name)
      else
        print("Applying unnamed filter.")
      end
  
      -- Get email addresses to use with filter
      local addresses = {}
      if (filter.addresses ~= nil) then
        addresses = filter.addresses
      else
        addresses = get_group_addresses(group)
      end
      print(#addresses .. " addresse(s) to check.")
  
  
      --[[
        Select messages from email addresses for filter
        and apply rules.
  
  	    Exclude flagged messages.
      ]]--
      local unmatched = all_messages - all_messages:is_flagged()
      local all_matches = {}
      if (#all_messages > 1000) then
        --[[
          More than 1000 messages to check.
          Apply rules after each address checked.
        ]]--
  
        for _, address in ipairs(addresses) do
          local matches = select_by_address(unmatched, address)
          apply_rules(account, group, filter, matches)
  
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
  
        apply_rules(account, group, filter, all_matches)
  
      end
  
    end
  
  
  end
  
  
  
  -- File and flag as per instructions in address book
  for i in pairs(contacts) do
  
    local group = contacts[i]
    if (group.filters and group.consolidate.destination == account) then
      
      organise_group(group)
      
    end
  
  end

end