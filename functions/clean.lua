--------------
-- Clean-up --
--------------

--- Archive older messages
-- @param account An IMAP account object. The account to clean.
-- @param working_set A set. The messages currently being processed.
function clean(account, working_set)

  announce("Cleaning")
  
  
  --- Find and apply any cleaning rules associated with filters in this group.
  -- @param group A table. The address book group currently being processed.
  -- @param working_set A set. The messages currently being processed.
  -- @return A set. All messages that remain in the working set after all the filters have bee applied.
  local function clean_group(group, working_set)
  
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
  
    -- Get the group to be cleaned
    local group_account = group.consolidate.destination
    log.info("Contact Group: " .. group.name .. " in " .. group_account.name .. ".")
    
    
    --- Move messages that meet a filter's conditions.
    -- @param destination_account An IMAP account object.  The account to move the messages to.
    -- @param destination_folder A string. The path to the folder to move the messages to (relative to the root of the destination_account).
    -- @param messages A set. The messages to move.
    -- @return A set. The messages that have been moved.
    local function apply_cleaning_rules(destination_account, destination_folder, messages)
    
      -- Move old messages to the folder specified in the target account
      if (#messages > 0) then
        messages:move_messages(destination_account[destination_folder])
      else
        log.info("0 messages moved.")
      end
      
      return messages
    
    end -- apply_cleaning_rules()
    
    
    -- Process all the filters in this group to find and apply cleaning rules
    for _, filter in ipairs(group.filters) do
    
      if (filter.clean) then
      -- This filter has cleaning rules
      
        -- Get the name of the folder to clean
        local source_folder = filter.folder
        local all_messages = Set {}
        if (source_folder == nil) then        
          -- No folder specified
          
          -- Default to the Inbox associated with this group
          source_folder = "INBOX"
          
          -- Default to the current working set
          all_messages = working_set
          
        else
       
          -- Select all messages in the source folder
          all_messages = group_account[source_folder]:select_all()
       
        end
        
        -- Narrow the selection of messages down to just those
        -- that meet the filter conditions
        all_messages = apply_filter_conditions(group, filter, all_messages)
        
        -- Narrow down the selection of messages to only those 
        -- that also meet the conditions of the clean filter
        all_messages = apply_cleaning_conditions(group, filter, all_messages)
      
        -- Get the name of the folder to move messages to      
        local destination_folder = filter.clean.folder
        if (destination_folder == nil) then
          
          -- No destination specified, default to the Deleted folder
          destination_folder = group_account["Deleted LITE"]
        end 
        
        -- Carry out the actions specified in the clean filter
        local moved = apply_cleaning_rules(group_account, destination_folder, all_messages) 
        
        if (source_folder == "INBOX") then
          working_set = working_set - moved
        end
        
        if (destination_folder == "INBOX") then
          working_set = working_set + moved
        end
        
      end
   
    end
    
    return working_set
    
  end -- clean_group()

  
    
  -- Loop through groups, applying filters to messages that meet the filter conditions
  for _, group in pairs(address_book.groups) do
      
    if (group.filters and group.consolidate.destination == account) then
      -- The filters in this group apply to the current account
      
      -- apply this group's filters to the working set and
      -- return all messages from the working set that remain in the Inbox
      working_set = clean_group(group, working_set)
      
    end
  
  end

      
end -- clean()