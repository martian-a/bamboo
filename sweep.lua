-----------
-- Sweep --
-----------

function sweep(accounts) 

  announce("Sweep")

  local function sweep_account(account, destination_account)
  
    -- Validate
    if (account == nil) then
      print("! Error: account not specified.")  
      return 
    elseif (destination_account == nil) then
      print("! Error: destination account not specified.") 
      return
    end
  
    -- Select all messages remaining in the account inbox
    local all_messages = account.INBOX:select_all()
   
    -- Select all messages that haven't been flagged 
    local unexpected = all_messages - all_messages:is_flagged()
     
    if (#unexpected > 0) then  
    
      print("Sweeping " .. account.name)
    
      -- Move all unexpected mail to the sweep destination account   
      unexpected:move_messages(destination_account["INBOX"])
    
    else
      print("0 messages to move from " .. account.name)
    end 
    
  end


  -- Sweep-up any unexpected mail, as per instructions in accounts
  for _, account in pairs(accounts) do
    
    local destination_account = get_account(account.sweep.destination)
    if (destination_account ~= nil) then
      sweep_account(account, destination_account)
    end
    
  end 
  
end