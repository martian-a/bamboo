---------------------------
-- Clean-up Old Messages --
---------------------------

print(" \n\n== Cleaning ==\n")

function clean(address_group, mode, destination_folder)

  print("\n")

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
  

  local group = contacts[address_group]
  print("Contact Group: " .. group.name)

  local destination_account = group.consolidate.destination
  
  local days = group.clean.days
  if (days == nil) then
    days = 1
  end 
  
  if (destination_folder ==  nil) then
    destination_folder = group.clean.folder
  end
  
  --[[
    Get all the messages in the current destination account 
    that are older than the current days limit
  ]]--
  local old_messages = destination_account.INBOX:is_older(days)
  print(#old_messages .. " messages > " .. days .. " days in " .. destination_account.name .. ".")
  
  if (not group.clean.starred) then  
    -- Ignore old messages that are starred
    old_messages = old_messages - old_messages:is_flagged() 
    print("...ignoring messages that are flagged.\n" .. #old_messages .. " messages to check.")
  end    

  
  -- Check that there are old messages to potentially clean
  if (#old_messages > 0) then 

    -- Get the addresses for the current group
    local addresses = group.addresses
    print(#addresses .. " addresses to check.")
         
    -- Select messages to clean up
    local messages = {}
    for i = 1, #addresses do
      
      local address = addresses[i]
      local related = {} 
      if (mode == "direct") then
        related = old_messages:contain_from(address)
      elseif (mode == "indirect") then
        related = 
            old_messages:contain_to(address)
          + old_messages:contain_cc(address) 
          + old_messages:contain_bcc(address)  
      elseif (mode == "default") then
        --[[
          No modes specified for address group.
          Default to checking from address.
        ]]--
        related = old_messages:contain_from(address)             
      else
         -- do nothing
      end
      
      if (#related > 0) then
        messages = messages + related
      end  
      
    end -- select messages
      
    -- Move old messages to the folder specified in the target account
    if (#messages > 0) then
      messages:move_messages(destination_account[destination_folder])
    else
      print("0 messages moved.")
    end
  
  end -- Check there are old messages to potentially clean

end -- clean() 


clean("family", "direct")
clean("friends", "direct")
clean("friends", "indirect")
clean("family", "indirect", "Saved/Friends")
clean("priority", "default")
