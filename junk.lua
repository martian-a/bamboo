---------------------------
-- Junk --
---------------------------

function junk(accounts)

  announce("Junk Mail")

  function clear_junk(account)
  
  
    -- Validate
    if (account == nil) then
      print("! Error: account not specified.")
    end
  
    -- Select all messages remaining in the account inbox
    local all_messages = account.INBOX:select_all()
  
    -- Select likely junk messages
    local junk = {}
  
    -- Select all messages that haven't been flagged
    junk = all_messages - all_messages:is_flagged()
  
    -- Flag likely junk messages as such
    flag_messages(account, junk, "Junk")
  
  
    -- Select all messages in the spam folder
    local spam = {}
    if (folder_exists(account, "Spam")) then
      spam = account["Spam"]:select_all()
    end
  
    -- Merge junk with spam
    local suspicious = junk + spam
  
    -- Move all suspicious mail to the Junk folder
    suspicious:move_messages(account["Junk"])
  
  end
  
  
  -- Identify likely junk mail in each account and move to junk folder.
  for _, account in ipairs(accounts) do
  
    clear_junk(account)
  
  end

end