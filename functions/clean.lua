--------------
-- Clean-up --
--------------

--[[
  Archive older messages and move likely 
  junk mail into the junk folder.
]]--
function clean(accounts)

  announce("Cleaning")
  
  
  local function clean_group(address_group, mode, destination_folder)
  
    -- Validate
    if (address_group == nil) then  
      print("! Error: address_group not specified.")
      return
    elseif (mode == nil) then
      print("! Error: mode not specified.")
      return
    elseif (contacts[address_group] == nil) then
      print("! Error: invalid address_group.")
      return    
    elseif (contacts[address_group].consolidate == nil or contacts[address_group].consolidate.destination == nil) then
      print("! Error: account not specified.")
      return    
    elseif (contacts[address_group].clean == nil) then
      print("! Error: clean rules not specified.")
      return
    elseif (contacts[address_group].clean.folder == nil and destination_folder == nil) then
      print("! Error: destination folder not specified.")
      return
    elseif (contacts[address_group].clean.folder == "INBOX" or destination_folder == "INBOX") then
      print("! Error: destination folder is same as folder to be cleaned.")
      return
    end
    
    -- Get the group to be cleaned
    local group = contacts[address_group]
    print("Contact Group: " .. group.name)
    print("Mode: " .. mode)
  
    -- Get the account to be organised
    local destination_account = group.consolidate.destination
    
    -- Get the max age of messages for this group (in days)
    local days = group.clean.days
    if (days == nil) then
      days = 1
    end 
    
    -- Get the name of the folder to move messages to
    if (destination_folder ==  nil) then
      destination_folder = group.clean.folder
    end
    
    --[[
      Get all the messages in the current destination account 
      that are older than the current days limit
    ]]--
    local old_messages = destination_account.INBOX:is_older(days)
    print(#old_messages .. " messages > " .. days .. " days in " .. destination_account.name .. ".")
    
    
    -- Check whether starred messages should be ignored
    if (not group.clean.starred) then  
      -- Ignore old messages that are starred
      old_messages = old_messages - old_messages:is_flagged() 
      print("...ignoring messages that are flagged.\n" .. #old_messages .. " messages to check.")
    end    
  
  
    --[[
      The rules to apply to any matches.
    ]]--
    local function apply_rules(account, folder, messages)
    
      -- Move old messages to the folder specified in the target account
      if (#messages > 0) then
        messages:move_messages(destination_account[destination_folder])
      else
        print("0 messages moved.")
      end
    
    end
  
    
    -- Check that there are old messages to potentially clean
    if (#old_messages > 0) then 
  
      -- Get the addresses for the current group
      local addresses = get_group_addresses(group)
      print(#addresses .. " addresses to check.")
      
      
      local function select_by_address(messages, address, mode)
      
        if (mode == nil or not(mode == "indirect")) then
          mode = "direct"
        end
      
        print("- checking " .. address)
        local matches = {} 
        if (mode == "indirect") then
          matches = 
              messages:contain_to(address)
            + messages:contain_cc(address) 
            + messages:contain_bcc(address)            
        else
          matches = messages:contain_from(address)
        end    
        print("...found " .. #matches .. " messages.")
      
        return matches
      end
           
      --[[
        Select messages from email addresses in group
        and apply rules.
      ]]--
      local unmatched = old_messages
      local all_matches = {}
      if (#old_messages > 1000) then
        --[[ 
          More than 1000 messages to check.
          Apply rules after each address checked.
        ]]--
        
        for _, address in ipairs(addresses) do
          local matches = select_by_address(unmatched, address, mode)
          apply_rules(destination_account, destination_folder, matches)
          
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
          local matches = select_by_address(unmatched, address, mode)
          all_matches = all_matches + matches
          unmatched = unmatched - matches
        end
        
        apply_rules(destination_account, destination_folder, all_matches)
        
      end
        
    end -- Check there are old messages to potentially clean
  
  end -- clean() 
  
  
  
  -- Clean the mail in each account, per instructions in account
  for _, account in ipairs(accounts) do
    
    for _, job in ipairs(account.clean) do
      
      clean_group(job.group, job.mode, job.folder)
      
    end
      
  end

end