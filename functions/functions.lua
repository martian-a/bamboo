---------------
-- Functions --
---------------


--- Print message so that it is more noticeable on the screen
-- @param message The message to print
function announce(message)

  log.info("\n\n== " .. message .. " ==\n")
  
end


--- Count the number of rows in a table
-- @param table The table to size
-- @return An integer. The number of rows in the table.
function size(table)

  local count = 0
  for _ in pairs(table) do
    count = count + 1
  end
  
  return count
end


--- Print the status of one or more IMAP accounts
-- @param accounts. A table. A list of the accounts to check. Each row is expected to be a reference to an IMAP account object.
function status_report(accounts)

  -- Get the status of each IMAP account in accounts
  for _, account in ipairs(accounts) do
    local exist, unread, unseen, uidnext = account.INBOX:check_status()
    if (options.info == false) then
      log.info(account.name .. ":")
      log.info("* " .. exist .. " messages in total")
      log.info("* " .. unread .. " recent")
      log.info("* " .. unseen .. " unread")
    end
  end

end


--- Look-up an account by its ID
-- @param id A string.  The ID of the account sought.
-- @return An IMAP account object or nil. The account with the ID specified (if found) or, if no matching account is found, nil.
function get_account(id)

  -- Default result to null
  local account = nil
  
  if (id ~= nil) then
    -- ID is not null
    
    -- Check each known account to see whether it's ID matches the ID specified.
    for _, candidate in pairs(accounts) do
      if (candidate.id == id) then
        -- It's a match!
        
        -- Return the account found
        return candidate
      end
    end
  end

  -- No match found. Return null.
  return account
end


--- Populate an IMAP account object
-- @param data. The data from which to populate the object.
-- @return IMAP account object.
function create_account(data)

  log.info("Creating " .. data.name)
  
  -- Initialise an IMAP account object with the basics.
  local account = IMAP {
  
    -- Server address
    server = data.server,
    
    -- Account username
    username = data.username,
    
    -- Whether to use SSL
    ssl = data.ssl,
    
    -- Account password
    password = data.password
    
  }
 
  
  --[[
    Extend the object with non-standard data.
  ]]--
  
  -- ID (unique within this application)
  account.id = data.id

  -- Human-friendly account name
  account.name = data.name
  
  
  -- Custom settings
  account.custom_settings = {}
  
  -- Default "Stasis" settings
  account.custom_settings.stasis = {}
  
  -- Set the name of the folder to temporarily store excess messages in
  account.custom_settings.stasis.folder = "Stasis"
  
  -- Set the maximum number of messages that should be in the Inbox.    
  account.custom_settings.stasis.threshold = 1000
  
  -- Set the maximumn number of messages to return from stasis if space in Inbox.
  account.custom_settings.stasis.restore = 500
  
  -- Default junk/spam settings
  account.custom_settings.junk = {}
  
  -- Set default folder for holding junk mail.
  account.custom_settings.junk.folder = "Junk"
  
  -- Default deleted mail settings
  account.custom_settings.trash = {}
  
  -- Set default folder for holding deleted mail
  account.custom_settings.trash.folder = "Deleted"

    
  -- Settings related to excess mail
  if (data.custom_settings) then
  
    for class, table in pairs(data.custom_settings) do
  
      for key, value in pairs(table) do 
            
        if (not(account.custom_settings[class])) then
          account.custom_settings[class] = {}
        end
        
        if (value ~= nil) then
          account.custom_settings[class][key] = value
        end
        
      end
      
    end
    
  end

      
  
  if (account.custom_settings.stasis.threshold > 2000) then    
    -- Stasis threshold is more than the maximum (2000).
    
    -- Set to maximum.
    account.custom_settings.stasis.threshold = 2000
  
  elseif (account.custom_settings.stasis.threshold < 50) then    
    -- Stasis threshold is less than the minimum (50).
    
    -- Set to minimum.
    account.custom_settings.stasis.threshold = 50
    
  end
      
  
  if (account.custom_settings.stasis.restore > account.custom_settings.stasis.threshold) then    
    -- The number of messages to unfreeze is greater than the max limit for the Inbox
    
    -- Set to 25% of the threshold.
    account.custom_settings.stasis.restore = math.floor(account.custom_settings.stasis.threshold * 0.25)
    
  end

  log.info("- Stasis: " .. account.custom_settings.stasis.folder)
  log.info("- Junk: " .. account.custom_settings.junk.folder)
  log.info("- Trash: " .. account.custom_settings.trash.folder)
  log.info("- Sweep: " .. tostring(account.custom_settings.sweep ~= nil))
  
  
  -- Return the populated IMAP account object
  return account
end



--- Simultaneously flag and mark messages as important
-- @param messages A set.  The messages to flag
-- @param flag A string. The flag value to set
function flag_messages(messages, flag)
  
  if (flag == nil) then
    -- Flag value not specified
    
    -- Default to "Flagged"
    flag = "\\Flagged"
    
  end

  messages:add_flags({flag})
  messages:mark_flagged()

end


--- Check whether a folder already exists on the account specified
-- @param account An IMAP object representing the account to check
-- @param folder A string. A path to the folder relative to the root of the account.
-- @return boolean. True if the folder exists, false if it doesn't.
function folder_exists(account, folder)

  -- Retrieve a list of all folders on the account that share the folder path specified.
  local result = account:list_all('', folder)

  if (#result > 0) then
    -- At least one matching folder has been found
    return true
  end

  -- No matching folder was found.
  return false
end


--- Check whether a table contains a specific value
-- @param table The table to check
-- @param value A string. The value to look for.
-- @return boolean. True if the value is found in the table, false if it isn't.
function contains(table, value)
  
  -- If the table is empty, it can't contain the value
  if (table == nil) then
    return false
  end
  
  -- Loop through each entry in the table
  for _, entry in ipairs(table) do
  
    -- Check whether the current entry matches the value sought
    if entry == value then
      -- It's a match!
      return true
    end
  end

  -- The value wasn't found. Return false.
  return false
end


--- Consolidate one or more tables into a single 1-column table.
-- @param tables_in A table. May contain other tables, which will be resolved and merged.
-- @param table_out Another table (optional).
function merge_entries(tables_in, table_out)

  -- Check whether table_out is null
  if (table_out == nil) then
    -- Create an empty table to store the merged results in.
    table_out = {}
  end
  
  -- If tables_in and table_out are both empty, there is nothing to merge.  Return an empty table
  if ((tables_in == nil or tables_in == {}) and table_out == {}) then
    return table_out
  end
  
  -- If tables_in is null but table_out isn't, swap them.
  if ((tables_in == nil or tables_in == {}) and table_out ~= {}) then
    tables_in = table_out
    table_out = {}
  end
  
  
  -- Loop through all the entries in tables_in
  for _, table_entry in pairs(tables_in) do
    
    -- Check whether the current entry is a table  
    if (type(table_entry) == "table") then
      -- Current entry is a table
      
      -- Merge this table
      merge_entries(table_entry, table_out)
      
    elseif (table_entry == nil) then
      -- Current entry is null.  Do nothing.    
        
    elseif (not(contains(table_out, table_entry))) then
      -- Current entry value is not a table or null and 
      -- does not already exist in the result
      
      -- Add this entry to the result table
      table.insert(table_out, table_entry)
      
    end
    
  end
  
  -- Return the result table.
  return table_out
  
end


--- Build a list of all the email addresses associated with the specified address book filter
-- @param filter A table. An address book filter.
-- @return A table. All email addresses associated with the specified filter, with references to named lists resolved.
function get_filter_addresses(filter)

  -- Create an empty container to hold the results
  local filter_addresses = {}
  
  -- Find email related fields in the filter
  for key, value in pairs(filter) do
  
    if (key == "from") then
      -- List of sender addresses found.
      
      -- Copy sender addresses to the result list. 
      -- Merge them first to resolve any references to named lists and eliminate duplicates.
      filter_addresses.from = merge_entries(value)
      
    elseif (key == "to") then
      -- List of intended recipient addresses found.
      
      -- Copy recipient addresses to the result list.
      -- Merge them first to resolve any references to named lists and eliminate duplicates.
      filter_addresses.to = merge_entries(value)
    elseif (key == "cc") then
      -- List of intended copy recipients found.
      
      -- Copy copy recipients found to the result list.
      -- Merge them first to resolve any references to named lists and eliminate duplicates.
      filter_addresses.cc = merge_entries(value)
    end
  
  end
  
 
  if (filter_addresses.from == nil) then
    -- No sender addresses are associated with this filter.
    -- Create an empty table of sender addresses in the results.
    filter_addresses.from = {}
  end
  
  if (filter_addresses.to == nil) then
    -- No recipient addresses are associated with this filter.
    -- Create an empty table of recipient addresses in the results.
    filter_addresses.to = {}
  end
  
  if (filter_addresses.cc == nil) then
    -- No copy recipient addresses are associated with this filter.
    -- Create an empty table of copy recipient addresses in the results.
    filter_addresses.cc = {}
  end
  
  -- Return the result
  return filter_addresses  

end


--- Build a list of all the email addresses associated with the specified address book group
-- @param group A table. An address book group.
-- @param for_consolidation Boolean.  True if the addresses are being collected for use in the consolidation step, otherwise false. Defaults to false.
-- @return A table. All email addresses associated with the specified group, with references to named lists resolved.
function get_group_addresses(group, for_consolidation)
  
  -- Check whether a boolean argument has been provided for the for_consolidation parameter
  if (type(for_consolidation) ~= "boolean") then
    -- No valid value provided.
    
    -- Default to false 
    for_consolidation = false
    
  end
  
  -- Create a container to hold the results
  local all_addresses = {}
  
  --[[
    Add the group's default list of addresses
    to the list being built.
  ]]--
  for key, value in pairs(group) do
  
    if (key == "from") then
      all_addresses.from = merge_entries(value)
    elseif (key == "to") then
      all_addresses.to = merge_entries(value)
    elseif (key == "cc") then
      all_addresses.cc = merge_entries(value)
    end
  
  end
  
  if (all_addresses.from == nil) then
    all_addresses.from = {}
  end
  
  if (all_addresses.to == nil) then
    all_addresses.to = {}
  end
  
  if (all_addresses.cc == nil) then
    all_addresses.cc = {}
  end
  
 
  
  --[[
    Add all email addresses that are listed
    in any of the group's filters.
  ]]--
  if (group.filters) then

    local group_filters = group.filters

    --[[
      Check each of the group's filters
      for addresses.
    ]]--
    for _, filter in ipairs(group.filters) do
      
      -- Check whether the addresses in this filter are appropriate for use during the consolidation step
      -- If not specified in the filter, default to true.
      local include_in_consolidation = true
      if (filter.consolidate == false) then
        -- Filter says its addresses shouldn't be used during consolidation
        include_in_consolidation = false
      end
            
            
      if (for_consolidation and include_in_consolidation ~= true) then
        --[[ Addresses are being collected for the consolidation step and
             the addresses in this filter are to be ignored during consolidation
             Skip collection of this filter's addresses ]]--
      else
        -- Collect the addresses associated with this filter
        -- Merge them in with the group's addresses
      
        local filter_addresses = get_filter_addresses(filter)
                
        if (filter_addresses.from) then
          all_addresses.from = merge_entries(all_addresses.from, filter_addresses.from)
        end
        
        if (filter_addresses.to) then
          all_addresses.to = merge_entries(all_addresses.to, filter_addresses.to)
        end
        
        if (filter_addresses.cc) then
          all_addresses.cc = merge_entries(all_addresses.cc, filter_addresses.cc)
        end
        
      end

    end

  end
  
  return all_addresses

end


--- Count the total number of addresses in the table specified
-- @param addresses A table of addresses
-- @return integer. The total number of addresses.
function get_total_addresses(addresses)
  
  -- Resolve all references to named address lists and remove duplicate entries
  local all_addresses = merge_entries(addresses)
  
  -- Return a count of the resolved addresses
  return #all_addresses

end


--- Consolidate a list of keywords, resolving references to named lists and removing duplicates.
-- @param keywords_in A table. The list of keywords to consolidate.
-- @return A table. The result of the consolidation process.
function get_keywords(keywords_in)
  
  -- Flatten the list so that any referenced keyword lists are merged in and duplicate entries removed.   
  return merge_entries(keywords_in)

end



function select_by_address(messages, address, mode)

  -- Validate
  if (mode ~= "from" and mode ~= "to" and mode ~= "cc") then
    log.error("Invalid value. The value of mode must be either \'from\', \'to\' or \'cc\'.")
  elseif (address == nil) then
    log.error("Missing address. There must be an address to check.")
  end

  
  -- Create a container to hold all messages that match the address in the mode specified.
  local matches = Set {}
  
  -- If there are no messages to check, return the empty container
  if (messages == nil or #messages == 0) then
    return matches
  end
    
  log.info("- checking " .. address)  
  
  if (mode == "to") then
  
    -- Select messages that were sent to the address specified.
    matches = messages:contain_to(address)
  
  elseif (mode == "cc") then
  
    -- Select messages that were copied to the address specified.
    matches = 
      messages:contain_cc(address) +
      messages:contain_bcc(address)
  
  else
  
    -- Select messages that were sent from (or on behalf of) the address specified
    matches = 
      messages:contain_from(address) +
      messages:contain_field("Reply-To", address)   
      
  end
  log.info("...found " .. #matches .. " message(s).")

  return matches
end


--- Assess a collection of messages, returning only those that match the conditions specified by the filter.
-- @param group A table. The group the filter belongs to, as defined in address_book.
-- @param filter A table. The filter, as defined in address_book.
-- @param messages A set. The messages to filter.
-- @return A set. The subset of messages that match the filter requirements.
function apply_filter_conditions(group, filter, messages)

    -- Check whether there are any messages to filter
    if (#messages < 1) then
      -- There are no messages to filter.
      
      -- Return the empty set.
      return messages
    
    end    

 
    -- Log the name of the filter being applied
    if (filter.name) then
      log.info("\nChecking filter: " .. filter.name)
    else
      log.info("Checking unnamed filter.")
    end
    
    -- Log the total number of messages to check
    log.info(#messages .. " to check.")

    -- Log how many of the messages are flagged.    
    local flagged = messages:is_flagged()
    log.info(#flagged .. " are flagged.")
    flagged = nil    

    -- Get email addresses to use with filter
    local all_addresses = get_filter_addresses(filter)
    
    -- Count the addresses (multi-dimensional table)    
    local total_addresses = get_total_addresses(all_addresses)
    
    if (total_addresses < 1) then
      -- This filter has no specific addresses associated with it
      
      -- Use all of the addresses associated with the group instead
      all_addresses = get_group_addresses(group)
      
      -- Update the count of addresses
      total_addresses = get_total_addresses(all_addresses) 
    
    end
    
    -- Log the total number of addresses associated with this filter
    log.info(total_addresses .. " address(es) to check")        
  
    -- Create a container to hold all the messages that match the filter conditions
    local all_matches = Set {}    
        
    -- Check (again) whether there are any addresses to use.
    if (total_addresses > 0) then
      -- There are address requirements

      -- Loop through each of the address modes (to|from|cc)
      for mode, mode_addresses in pairs(all_addresses) do
    
        -- Check whether there are any addresses listed for this mode (to|from|cc)
        if (#mode_addresses > 0) then
          -- There are addresses to use
      
          -- Log which mode this is.
          log.info("Mode: " .. mode)
        
          -- Loop through all the addresses for this mode
          for _, address in ipairs(mode_addresses) do
            
            -- Select all messages that contain the current address in the field matching the current mode
            local matches = select_by_address(messages, address, mode)
            
            -- Add any selected messages to the collection of matches 
            all_matches = all_matches + matches
            
            -- Remove the same selected messages from the messages collection
            -- (There's no point in checking them again as they already match an address requirement)
            messages = messages - matches
          
          end
          
        end
        
      end
      
      
      -- Check whether any messages match the filter address requirements
      if (#all_matches < 1) then
        -- No messages have met the address requirements. 
      
        -- Stop the filter.  Return an empty set.
        log.info("No messages match the filter address conditions.")
        return all_matches
        
      else
        -- Messages have met the address requirements.
        
        -- Replace the full list of messages to check with 
        -- just those that have passed the address requirements.
        messages = all_matches

      end  
      
    else
      
      -- No address requirements.  All messages match so far.
    
    end


    -- Select messages with a subject line that matches the keyword conditions
    if (filter.keywords) then

      --[[
        Move all messages that have passed the address requirements
        into the unmatched collection, as they have yet to meet the
        keyword requirements.  Reset the matches container to empty.
      ]]-- 
      all_matches = Set {}
    
      for _, keyword in ipairs(get_keywords(filter.keywords)) do

        local matches = messages:contain_subject(keyword)
        all_matches = all_matches + matches
        messages = messages - matches

      end
    else
    
      -- No keyword requirements.  All remaining messages match.
      
    end
    
    log.info(#all_matches .. " messages match all the filter conditions.")
    
    return all_matches
  
end


--- Assess a collection of messages, returning only those that match the cleaning conditions associated with a filter.
-- @param group A table. The group the filter belongs to, as defined in address_book.
-- @param filter A table. The filter, as defined in address_book.
-- @param messages A set. The messages to filter.
-- @return A set. The subset of messages that match the filter requirements.
function apply_cleaning_conditions(group, filter, messages)
      
      
  -- Get the max age of messages for this folder (in days)
  local days = filter.clean.days
  if (days == nil) then
    days = 1
  end 


  -- Get all the messages in the source account that are older than the current days limit
  local messages = messages:is_older(days)
  log.info(#messages .. " messages > " .. days .. " days.")


  -- Check whether starred messages should be ignored
  if (not(filter.clean.starred) or filter.clean.starred == false) then
  
    -- Ignore old messages that are starred
    messages = (messages - messages:is_flagged())  
    log.info("...ignoring messages that are flagged.")
     
  end
  
  return messages

end   



--- Select all the messages currently in the stasis folder (if any).
-- @param account An IMAP account object. The account that the stasis folder belongs to.
-- @return A set. All the messages currently in the stasis folder.
function get_messages_in_stasis(account)

  -- Retrieve the path to the account's stasis folder
  local stasis_folder = account.custom_settings.stasis.folder
  
  -- Create an empty container to hold all the messages in stasis
  local held_messages = Set {}
  
  -- Check whether the stasis folder exists
  if (folder_exists(account, stasis_folder)) then
    -- It does.
    
    -- Select all the messages in the stasis folder
    held_messages = account[stasis_folder]:select_all()
    
  end
  
  -- Return all the messages in the stasis folder
  return held_messages
    
end
