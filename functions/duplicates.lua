----------------
-- Duplicates --
----------------

--- Remove duplicates from a collection of messages.
-- @param account An IMAP account object
-- @param source The folder containing the messages to be filtered.
-- @param temp The folder to use as a working area during the filtering process.  
-- @usage duplicates(catchall, "Saved Mail", "temp_dedupe")
function duplicates(account, source, temp)


  announce("De-duping")
  
  
  --- Determine whether two messages are the same.
  -- @param message A message.
  -- @param candidate Another message.
  -- @return boolean. True if the message and candidate are the same. False if they're different.
  local function is_equal(message, candidate)

    local message_mailbox, message_uid = table.unpack(message)
    local candidate_mailbox, candidate_uid = table.unpack(candidate)

    -- Establish the size of message    
    if (message.size == nil) then
      message.size = message_mailbox[message_uid]:fetch_size()
    end
    
    -- Establish the size of candidate
    if (candidate.size == nil) then
      candidate.size = candidate_mailbox[candidate_uid]:fetch_size()
    end
    
    -- Check whether the message and candidate are the same size
    if (message.size ~= candidate.size ) then    
      -- The message and candidate are different sizes.
      
      -- Return false because the message and candidate are not the same.
      return false
    
    end
    
    -- Check whether the message and candidate share the same date
    if (message_mailbox[message_uid]:fetch_date() ~= candidate_mailbox[candidate_uid]:fetch_date()) then
      -- The message and candidate have different dates
      
      -- Return false because the message and candidate are not the same.
      return false
      
    end
    
    -- A list of fields to compare
    local fields = {"subject", "to"}
    
    -- Check each of the listed fields
    for _, fieldname in pairs(fields) do
      
      -- Check whether the message and candidate share the same field value
      if (message_mailbox[message_uid]:fetch_field(fieldname) ~= candidate_mailbox[candidate_uid]:fetch_field(fieldname)) then
        -- The message and candidate have different field values
        
        -- Return false because the message and candidate are not the same.
        return false
        
      end

    end
    
    -- Check whether the message and candidate share the same body.
    if (message_mailbox[message_uid]:fetch_body() ~= candidate_mailbox[candidate_uid]:fetch_body()) then
      -- The message and candidate have different bodies.
      
      -- Return false because the message and candidate are not the same.
      return false
      
    end
    
    
    -- Return true because the message and candidate are the same.
    return true
  
  end -- is_equal()
  
  
  --- Move messages to a new folder, a chunk at a time.
  -- @param messages A set of messages.
  -- @param target A reference to the folder to move the messages to.
  -- @param threshold The maximum number of messages to move.
  local function move(messages, target, threshold)

    log.info(#messages .. " message(s) to move")
    log.info("Threshold: " .. threshold)
    
    -- Get the max number of messages to move at a time
    local chunk_size = 500
    
    -- Check whether the total number of messages in the set is less than the chunk size
    if (#messages < chunk_size) then
      -- There are fewer messages to move than the chunk size
      
      -- Reduce the chunk size to the total number of messages
      chunk_size = #messages
    end
    
    -- Zero a counter for tracking the total number of messages moved
    local moved = 0
    
    --[[
      Move messages into the target folder, a chunk at a time
      Stop when either:
      - there are no messages left to move, or
      - the number of messages moved is equal to the threshold specified
    ]]--
    while (moved < threshold and #messages > 0) do

      -- Select a chunk (subset) of messages to move
      local selected = Set {}
      for i = 1, chunk_size do
        table.insert(selected, table.remove(messages))
      end
            
      -- Move this chunk to the target folder
      selected:move_messages(target)
      
      -- Update the total number of messages moved to include the total in this chunk
      moved = moved + #selected
        
    end

  end -- move()
  
  
  --- Split a collection of messages into smaller sets 
  -- Each new subset of messages will be moved to its own folder.
  -- @param account An IMAP account object.
  -- @param source A reference to the folder containing the messages to subdivide.
  -- @param target A reference to the folder that will be parent to the folders containing the new subcollections.
  -- @return A table, comprising a list of all the sub-folders in the target folder.
  local function disperse(account, source, target)
            
    -- The maximum number of messages each subset should contain
    local max_subset_size = 5000
    
    -- Initialise a counter of the collection sub-folders
    local folder_number = 1

    -- Select the collection of messages to be split
    local messages = account[source]:select_all()     

    -- Move each message into a new folder
    while (#messages > 0) do
      
      -- A path to the sub-folder that the current subset will be moved to
      local folder_name = target .. "/" .. folder_number
      log.info("Filling folder: " .. folder_name)
      
      -- Select any messages that are already in the sub-folder
      local remnants = Set {}
      if (folder_exists(account, folder_name)) then
        remnants = account[folder_name]:select_all()
      end
      log.info("- remnants: " .. #remnants)
      
      -- Check whether the sub-folder is already full
      if (#remnants < max_subset_size) then
        -- The sub-folder is not yet full
        
        -- Fill the sub-folder with messages from the source collection, in chunks
        move(messages, account[folder_name], (max_subset_size - #remnants))
        
        -- Update the list of source messages (so any that have now been moved are excluded)
        messages = account[source]:select_all()     
      
      else
        -- The sub-folder is already full
      end 
      
      -- Move to the next sub-folder
      folder_number = folder_number + 1
      
    end -- All the messages have been moved.
  
    -- Return a list of all the sub-folders in the target folder.
    return account:list_all(target)
  
  end -- disperse()
  
  
  --- Extract the domain name from the email address used to send a message.
  -- @param A message. The message to parse.
  -- @return A string. The domain name (prepended with the @ character).
  local function get_sender_domain(message)
    
    local message_mailbox, message_uid = table.unpack(message)
    
    -- Retrieve the full value of the "From" field of the message
    local from_field = message_mailbox[message_uid]:fetch_field("from")
    log.info(from_field)
    
    -- Get the domain name of the sender from the value of the from field
    local domain = ""
    for token in string.gmatch(from_field, "@[%a%d_%-%.]+") do
      domain = token
    end
    log.info(domain)
    
    -- Return the domain address
    return domain
    
  end -- get_sender_domain()
  
  
  --- Select all messages from the sender specified
  -- @param account An IMAP account object.  The account containing the messages to check.
  -- @param folders A table, comprising a list of the folders to check for messages.
  -- @param sender A string. The domain name of the sender to search for.
  -- @param duplicates_folder A string. The name of the folder to put any duplicates found into.
  -- @return A set. A single copy of each of the messages checked.
  local function check_by_sender(account, folders, sender, duplicates_folder)
  
    -- A container to hold a unique copy of each message in the set checked.
    local checked = Set {}  
    
    -- Check each of the folders specified
    for _, foldername in pairs(folders) do

      log.info(#checked .. " unique messages from " .. sender .. " found so far")
      
      -- Select all the messages in the current folder
      local messages = account[foldername]:select_all()
      log.info(#messages .. " messages in " .. foldername)
      
      -- Select the sub-set of messages that were sent from the domain specified
      local same_sender = messages:contain_from(sender)      
        
      -- A container to hold any duplicates found 
      local duplicates = Set {}  
      
      -- Check all the messages in the current folder
      while (#same_sender > 0) do
               
        log.info(#same_sender .. " messages from " .. sender .. " in " .. foldername .. " to check.")
        
        -- Get a message from the sub-set sent from the domain specified
        local message = table.remove(same_sender)        
        
        local is_unique = true
        if (#checked > #same_sender) then
          --[[
            The collection of already checked unique messages from the sender is 
            larger than the collection of unchecked messages from the same sender
            in the current folder.
          ]]-- 
        
          -- Compare the message against the others from the same sender in the current folder
          for _, candidate in ipairs(same_sender) do
            
            -- Check whether the message is the same as the current candidate
            if (is_equal(message, candidate)) then
               -- The message is the same as the candidate
               
               -- Make a note that the message isn't unique
               is_unique = false
               
               -- Stop comparing this message to others from the same sender
               break
            end
            
          end
          
        end
          
        if (is_unique) then
          -- The message hasn't yet been identified as being a duplicate
          
          -- Compare the message against the other unique messages from the same sender in the other folders
          for _, candidate in ipairs(checked) do
        
            -- Check whether the message is the same as the current candidate
            if (is_equal(message, candidate)) then
              -- The message is the same as the candidate
              
              -- Make a note that the message isn't unique
              is_unique = false
              
              -- Stop comparing this message to others from the same sender
              break
            end
            
          end
          
        end
                    
                    
        if (is_unique) then
          -- The message isn't the same as any others from the same sender
          
          -- Add it to the list of unique messages
          table.insert(checked, message)
          
        else
          -- The message is the same as another from the same sender
          
          -- Add it to the list of duplicates
          table.insert(duplicates, message)
        
        end
                             
      end

      -- Move all duplicates founds so far into the duplicates folder
      duplicates:move_messages(account[duplicates_folder])

    end
    
    -- Return a single copy of each of the messages from the domain specified
    return checked
  
  end
  
  -- Names for folders to be used during the filtering process
  local unique = temp .. "/unique"
  local duplicates = temp .. "/duplicates"
  local pending = temp .. "/pending"
  local anomalies = temp .. "/anomalies"
  
  
  for _, foldername in pairs({unique}) do
     
    if (folder_exists(account, foldername)) then
      
      local unexpected = account[foldername]:select_all()
      
      if (#unexpected > 0) then
        log.error(#unexpected .. " unexpected messages.  Please empty " .. foldername .. " and start again.")
        return
      end
      
    end
    
  end
  
 -- Split them into smaller sub-sets
 -- Get a list of the folders containing the sub-sets
 local folders = disperse(account, source, pending)
 
 
 for i, foldername in pairs(folders) do
  log.info(i .. ": " .. foldername)
 end
 log.info("\n")
  
 for _, foldername in pairs(folders) do
    
    log.info("Starting in " .. foldername)
    
    repeat
    
      -- Get all the messages remaining in the temp folder
      local messages = account[foldername]:select_all()
      
      if (#messages > 0) then
      -- The folder's not empty yet
      
        -- Get the message that's currently first in this temp folder
        local first_message_in_folder = messages[1]
        
        -- Get the sender of the first message    
        local sender = get_sender_domain(first_message_in_folder) 
        
        if (sender == nil or sender == "") then
         
         local anomaly = Set {first_message_in_folder}
         anomaly:move_messages(account[anomalies])
        
        else
        
          log.info("Sender domain: " .. sender)
                  
          -- Check all other messages from this sender for duplicates, in all the temp folders
          local checked = check_by_sender(account, folders, sender, duplicates)
                   
          -- Merge the unique messages from this sender (from all the temp folders) into the unique folder     
          checked:move_messages(account[unique])
          
          checked:unmark_flagged()
          checked:mark_seen()
          
          log.file:close()
          
        end
        
      end
    
    until (#messages == 0)
    -- This temp folder is empty.
    -- Start processing the next temp folder.
    
  end
  
  
  -- Select all the unique messages 
  local messages = account[unique]:select_all()
  local threshold = #messages + 50
  
  -- Return the de-duped results back to the source folder
  move(messages, account[source], threshold)
      
end -- duplicates()