-----------
-- Sweep --
-----------

--- Apply rules for sweeping the remnants of an inbox into another account
--  @param account An IMAP account object.  The account to move messages from.
--  @param working_set A set.  The messages to process.  
--  @return A set.  The messages that remain in the account's inbox at the end of this step (excluding messages that have arrived since the filtering process began).
function sweep(account, working_set) 

  announce("Sweep")

  --- Move unflagged messages from the current account into the destination account
  -- @param account An IMAP account object.  The account to move messages from.
  -- @param destination_account An IMAP account object.  The account to move message to.
  -- @param all_messages A set. The messages from which the unflagged messages will be taken.
  -- @return A set. The messages that weren't moved. 
  local function sweep_account(account, destination_account, all_messages)
  
    -- Validate
    if (account == nil) then
      log.error("Account not specified.")  
      return 
    elseif (destination_account == nil) then
      log.error("Destination account not specified.") 
      return
    end
   
    -- Separate the messages into flagged and unflagged
    local flagged = all_messages:is_flagged()
    local unflagged = all_messages - flagged
     
    if (#unflagged > 0) then  
    
      log.info("Sweeping " .. account.name)
    
      -- Move all unexpected (unflagged remainder of working set) mail to the sweep destination account   
      unflagged:move_messages(destination_account["INBOX"])
    
    else
      log.info("0 messages to move from " .. account.name)
    end 
    
    -- Return the flagged remainder of the working set
    return flagged
    
  end


  -- Check whether this account has sweep rules
  if (account.custom_settings.sweep) then
    -- It does. Apply the rules.
    
    -- Get the IMAP account object for the account to sweep messages to
    local destination_account = get_account(account.custom_settings.sweep.destination)
    
    if (destination_account ~= nil) then
      -- Sweep destination account retrieved.
      
      -- Move messages into the destination account.
      working_set = sweep_account(account, destination_account, working_set)
    
    else
      
      log.error("Sweep destination account not found.")
    
    end
    
  end
  
  return working_set
end