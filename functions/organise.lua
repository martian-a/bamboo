--------------
-- Organise --
--------------

--- Move and/or flag messages according to conditions defined in filters
-- @param account An IMAP account object. The account to organise.
-- @param working_set A set. The messages currently being processed.
-- @return A set. All messages that remain in the account's inbox at the end of this step, excluding any that arrived after the step began.
function organise(account, working_set)

  announce("Organising")
  

  --- Find messages related to this group and move or flag as required.
  -- @param group A table. The address book group that defines the rules to be applied to the working set.
  -- @param working_set A set. The messages to apply the group's rules to.  
  local function organise_group(group, working_set)
  
    -- Validation
    if (group == nil) then
      log.error("Group not specified.")
      return
    elseif (group.consolidate == nil or group.consolidate.destination ==  nil) then
      log.error("Account not specified.")
      return
    elseif (group.filters == nil) then
      log.error("Filters not specified.")
      return
    end
  
    -- Get the account to be organised
    local account = group.consolidate.destination
    
    log.info("Organising " .. group.name .. " in " .. account.name .. ".")
  
    -- Get all the filters defined in this group
    local all_filters = group.filters
    log.info(#all_filters .. " filter(s) to apply.")
    
    
    --- Apply rules specified by a filter
    -- @param account An IMAP account object.  The account the group is associated with.
    -- @param group A table. The group that defines the rules to apply.
    -- @param filter A table. A set of rules to apply.
    -- @param messages A set. The messages to apply the rules to.
    -- @return A set. All messages moved as a result of applying these rules.
    local function apply_rules(account, group, filter, messages)
    
      if (messages == nil or #messages < 1) then
        -- There are no messages to apply the rules to. Return an empty set.
        return Set {}
      end
  
  
      if (filter.star == true) then
        -- The filter specifies that unread messages should be flagged         
        
        -- Flag unread matches   
        local unread = messages:is_unseen()
        log.info(#unread .. " messages haven't yet been read.")
        flag_messages(unread)
             
      end
      
      -- Separate the messages into flagged (including the newly flagged) and unflagged
      local flagged = messages:is_flagged()
      local unflagged = messages - flagged   
      log.info(#flagged .. " messages match the filter but are flagged and so will stay in the inbox.")
      
      
      -- Create container to hold all messages moved as a result of this filter
      local moved = Set {}
      
      if (filter.folder) then   
        -- The filter specifies a folder that unflagged messages should be moved to
                
        log.info(#unflagged .. " unflagged messages match the filter and will be moved.")
  
        -- Move the unflagged messages to the folder specified in address book
        unflagged:move_messages(account[filter.folder])
        
        -- Record which messages were moved
        moved = unflagged
                
      else
        
        log.info("There are no instructions to move the " .. #unflagged .. " matching, unflagged message(s).")
                
      end
      
      return moved
  
    end
 
    
    -- Loop through the group's filters, applying the filter actions to messages that meet the filter conditions
    for _, filter in ipairs(all_filters) do
  
      -- Select all messages in the inbox of the account to be organised
      local flagged = working_set:is_flagged()
      local unflagged = working_set - flagged
      flagged = nil
        
      -- Check that there are unflagged messages to organise  
      if (#unflagged > 0) then
      
        -- Check that there is an action to implement
        if (filter.folder or filter.star) then
        
          -- Check that there are organisation-related requirements to meet
          if (filter.keywords or (filter.to or filter.from or filter.cc)) then
            
            --[[
              Select messages that match the filter address and keyword conditions.
              Exclude flagged messages.
            ]]--
            local matches = apply_filter_conditions(group, filter, unflagged)  
        
            -- Apply the filter actions to all the messages at once
            local moved = apply_rules(account, group, filter, matches)
            working_set = working_set - moved
          
          end
        
        end        
      
      end
  
    end
  
    return working_set
    
  end
  
  
  
  -- Loop through groups, applying filters to messages that meet the filter conditions
  for _, group in pairs(address_book.groups) do
      
    if (group.filters and group.consolidate.destination == account) then
    -- The filters in this group apply to the current account
      
      -- apply this group's filters to the working set and 
      -- return all messages from the working set that remain in the Inbox
      working_set = organise_group(group, working_set)
      
    end
  
  end
  
  return working_set

end