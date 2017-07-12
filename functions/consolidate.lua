--------------------------
-- Consolidate Messages --
--------------------------

--- Move messages between accounts.
-- @param account An IMAP account object.  The account to move messages from.
-- @return A set. All messages that remain in the account's inbox at the end of this step, excluding any that arrived after the step began.
function consolidate(account)

  announce("Consolidating")


  --- Find messages handled by this group and move them to the primary account associated with this group.
  -- @param account An IMAP account object.  The account that messages will be moved from.
  -- @param group A table. The address book group currently being processed.
  -- @param all_messages A set. All messages that currently remain in the account's inbox (excluding any that have been moved or arrived since this step began).
  -- @param return A set. All messages that remain in the account's inbox after this group has been processed (excluding any that have arrived since the process began)
  local function consolidate_group(account, group, all_messages) 
    
    -- Validation
    if (account == nil) then
      log.error("Account not specified.")
      return
    elseif (group == nil) then
      log.error("Group not specified.")
      return
    elseif (group.consolidate == nil or group.consolidate.destination == nil) then
      log.error("Destination account not specified.")
      return
    end
    
    log.info("\nConsolidating " .. group.name .. " in " .. account.name .. ".")
    log.info(#all_messages .. " messages to check.")
    
    -- Get email addresses of group
    local addresses = merge_entries(get_group_addresses(group, true))
    log.info(#addresses .. " addresses to check.")
      
    
    --- Find messages that were sent or recieved by the address specified. 
    -- @param messages A set.  The messages to search.
    -- @param address A string.  The value to search for.
    -- @return A set. The subset of messages that contain the address in a sender or recipient field.
    local function select_by_address(messages, address)
    
      if (messages == nil or #messages == 0) then
        -- There are no messages to check. Return an empty set.
        return Set {}
      end
    
      log.info("- checking " .. address)
      local matches = 
            messages:contain_from(address)
          + messages:contain_cc(address)
          + messages:contain_bcc(address)
          + messages:contain_to(address)
          + messages:contain_field("Reply-To", address)  
      log.info("...found " .. #matches .. " messages.")
    
      return matches
      
    end  -- select_by_address()
     
    
    -- Initialise the set of unmatched messages with all messages to check. 
    local unmatched = all_messages
 
    -- Create an empty container to hold all messages to/from an address associated with this group.
    local all_matches = Set {}
    
    -- Loop through all the addresses associated with this group.
    for index, address in ipairs(addresses) do
    
      -- Find all the messages to/from the current address
      local matches = select_by_address(unmatched, address)
      
      -- Add the matches to the collection of messages associated with this group.
      all_matches = all_matches + matches

      -- Remove the matches from the collection of messages to check.
      unmatched = unmatched - matches
      
    end
    
    if (#all_matches > 0) then
      -- Messages associated with this group were found.
      
      -- Move messages associated with a group in another account to that other account
      all_matches:move_messages(group.consolidate.destination["INBOX"])
      
    else
      -- No messages associated with this group were found.
    
      log.info("0 messages to move.")
    
    end
      
    -- return the messages that remain in the Inbox after consolidation
    -- (thus excluding any that have arrived since the process began)  
    return unmatched
   
  end  -- consolidate_group()
  
  
  
  --[[
    Select all messages in the inbox of the primary account.
    This set will be passed on to subsequent subroutines and may shrink,
    as messages are identified as being irrelevant to the subsequent processes,
    but should never grow, as messages need to go through the steps 
    in order.
  ]]--
  local working_set = account.Inbox:select_all()
  log.info("Working set: " .. #working_set .. " (" .. account.name .. ")")


  --[[
    Loop through all the groups in the address book
    in order of priority, as set in the groups themselves.
  ]]-- 
  for order = 1, size(address_book.groups) do
    
    for _, group in pairs(address_book.groups) do   
         
      if (group.consolidate.order == order and not(group.consolidate.skip)) then
        
        -- Loop through all the sources listed for the current group. 
        for _, source in ipairs(group.consolidate.check) do          
                      
          -- Check whether the primary account is listed as a source            
          if (source == account) then
            -- The primary account is listed as a source for this group.
            
            --[[
              Search the inbox of this (primary) account for messages
              that should be moved to the account listed as the target for
              this group.
             ]]--
            working_set = consolidate_group(source, group, working_set)
          
          end
          
        end
        
      end
    
    end
    
  end
  
  return working_set
  
end
