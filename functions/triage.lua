------------
-- Triage --
------------

--- Extreme measures for large inboxes
-- @param account An IMAP account object. The account to triage.
function triage(account)

  announce("Triage")

  log.info("Account: " .. account.name)

  -- Select all messages in the inbox of the account to be organised
  local inbox_messages = account.INBOX:select_all()
  

  --- Move excess messages from the account's inbox into the stasis folder
  -- @param account An IMAP account object.  The account to manage.
  local function freeze(account)

    -- Select all messages in the inbox of the account to be organised
    local messages = account.INBOX:select_all()
    log.info(#messages .. " message(s)")

    -- Get the name of the folder used for temporarily storing overflow from the Inbox
    local stasis_folder = account.custom_settings.stasis.folder
    
    -- Get the max size of the Inbox
    local stasis_threshold = account.custom_settings.stasis.threshold
    
    -- Get the max number of messages to move into stasis at a time
    local chunk_size = account.custom_settings.stasis.restore
    
    -- Zero a counter for tracking the total number of messages put into stasis
    local moved = 0
    
    -- Move excess messages into the temp folder (stasis)
    while #messages > stasis_threshold do

      local selected = Set {}
      for i = 1, chunk_size do
        table.insert(selected, messages[i])
        moved = moved + 1
      end

      account.INBOX:move_messages(account[stasis_folder], selected)

      log.info("Moved so far: " .. moved)
      messages = account.INBOX:select_all()
    end

  end -- freeze()


  --- Move excess messages from the stasis folder back into the account's inbox.
  -- @param account An IMAP account object.  The account to manage.
  local function restore(account)


    -- Get the name of the folder used for temporarily storing overflow from the Inbox
    local stasis_folder = account.custom_settings.stasis.folder
    
    -- Get the max size of the Inbox
    local stasis_threshold = account.custom_settings.stasis.threshold

    -- Calculate how many messages can be moved back into Inbox
    local space_available = (stasis_threshold - #inbox_messages)

    -- Select all messages currently held in stasis
    local held_messages = get_messages_in_stasis(account)
    log.info("There are currently " .. #held_messages .. " message(s) in stasis.")

    -- Check that there's room in the Inbox to restore some messages
    if (space_available < 1) then
      log.info("Insufficient space in Inbox to restore messages.")
      return
    end

    -- Move messages back out of the temporary folder, into the Inbox.
    -- Move back as many as possible without exceeding the max size of the Inbox.
    if (#held_messages > space_available) then

      local selected = Set {}
      for i = 1, space_available do

        table.insert(selected, held_messages[i])

      end

      account[stasis_folder]:move_messages(account.INBOX, selected)

    else

      held_messages:move_messages(account.INBOX)

    end

  end -- restore()


  -- Get the max allowed size of the Inbox
  local stasis_threshold = account.custom_settings.stasis.threshold
  
  -- Select all messages currently in stasis
  local messages_in_stasis = get_messages_in_stasis(account)

  -- Check whether there are too many messages in the inbox
  if (#inbox_messages > stasis_threshold) then

    -- Move overflow into a temporary folder
    freeze(account)

  elseif (#messages_in_stasis > 0) then

    -- Move overflow back into inbox
    restore(account)

  else

    log.info("No triage required.")

  end

end -- triage()
