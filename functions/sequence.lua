--------------
-- Sequence --
--------------


--- Flow control for the filtering process.
-- @param accounts A set. All IMAP account objects defined in the accounts data file.
-- @param account An IMAP account object. The primary account to be filtered.
function filter(accounts, account)

  announce("* Filtering starting *")
  
  -- Load email address lists (global: contacts)
  dofile("data/address_book.lua")
  
  local function status_update(account, working_set)
    log.info("working_set: " .. #working_set .. " (" .. account.name .. ")")  
  end
  
  
  -- Print a summary of the contents of the inbox of each account
  status_report(accounts)
  
  -- Manage overflow from the inbox, per rules in the account data file.
  triage(account)
  
  -- Move messages between accounts, per rules in the address book.
  local working_set = consolidate(account)
  status_update(account, working_set)
  
  -- File messages into folders, per rules in the address book.
  working_set = organise(account, working_set)
  status_update(account, working_set)
  
  -- Move the remains of the working set into another account, per rules in the account data file.
  working_set = sweep(account, working_set)
  status_update(account, working_set)
  
  -- Manage messages suspected to be junk
  working_set = junk(account, working_set)
  status_update(account, working_set)
  
  -- Archive messages, per rules in the address book.
  clean(account, working_set)

  announce("* Filtering complete *")

  -- If messages remain in the overflow folder, filter again.
  if (#get_messages_in_stasis(account) > 0) then
    filter(accounts, account)
  end
  
end