------------
-- Triage --
------------

print(" \n\n== Triage ==\n\n")


--[[
  Extreme measures for large inboxes.
]]--
for _, account in ipairs(accounts) do

  print("Account: " .. account.name)

  -- Select all messages in the inbox of the account to be organised
  local inbox_messages = account.INBOX:select_all()
  
  --[[
    The name of the folder used for temporarily storing
    overflow from the Inbox.
  ]]--
  local temp_folder = "Stasis"
     
     
  local function triage(account, temp_folder)
   
    -- Select all messages in the inbox of the account to be organised
    local messages = account.INBOX:select_all()
    print(#messages .. " messages")

    local chunk_size = 500
    local moved = 0  
    while #messages > 1950 do
      
      local selected = {}
      for i = 1, chunk_size do
        table.insert(selected, messages[i]) 
        moved = moved + 1
      end
      
      account.INBOX:move_messages(account[temp_folder], selected)      
    
      print("Moved so far: " .. moved)
      messages = account.INBOX:select_all()
    end
    
  end -- triage()    
     
     
  local function restore(account, temp_folder, space_available)
  
    local held_messages = account[temp_folder]:select_all()
    print("There are currently " .. #held_messages .. " messages in stasis.")
    
    if (space_available < 1) then
      print("Insufficient space in Inbox to restore messages.")
      return
    end
    
    if (#held_messages > space_available) then
    
      local selected = {}
      for i = 1, space_available do
        
        table.insert(selected, held_messages[i])
        
      end
      
      account[temp_folder]:move_messages(account.INBOX, selected)
      
    else
      
      held_messages:move_messages(account.INBOX)
    
    end
    
  end -- restore()   
     

  -- Check whether there are too many messages in the inbox
  if (#inbox_messages > 2000) then
     
    -- Move overflow into a temporary folder 
    triage(account, temp_folder)
  
  elseif (folder_exists(account, temp_folder)) then
    
    -- Calculate how many messages can be moved back into Inbox    
    local space_available = (2000 - #inbox_messages) - 50
    
    -- Move overflow back into inbox
    restore(account, temp_folder, space_available)
    
  else
  
    print("No triage required.")
  
  end

end
