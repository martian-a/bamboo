---------------------------
-- Junk --
---------------------------

--- Identify likely junk mail in each account and move to junk folder  
-- @param account An IMAP account object. The account to check.
-- @param working_set A set. The messages to be assessed.
-- @return A set. The messages from the working set that remain in the inbox after this step.
function junk(account, working_set)

  announce("Junk Mail")
  
  -- Validate
  if (account == nil) then
    log.error("Account not specified.")
  end

  -- Create a container to hold junk messages.
  local junk = Set {}

  -- Select all messages in the working set that are flagged
  local flagged = working_set:is_flagged()
  
  -- Initialise the collection of junk messages with all messages in the working set that aren't flagged. 
  junk = working_set - flagged

  -- Create a container to hold spam messages.
  local spam = Set {}
  
  -- Move all suspicious mail to the Junk folder
  junk:move_messages(account[account.custom_settings.junk.folder])
  
  -- Return the flagged messages
  return flagged

end