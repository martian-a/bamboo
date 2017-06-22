-------------
-- Options --
-------------

-- Time to wait (in seconds) for the mail server to respond.
options.timeout = 120

-- If a target folder doesn't exist, create it
options.create = true

-- Auto-subscribe to any new folder that's created
options.subscribe = true

-- Don't delete all messages marked for deletion at the end of the session
options.close = false

-- Use a TLS connection (if server supports it) 
options.starttls = true

-- Ignore certificate mismatches :(
options.certificates = false


----------------------
-- Global Functions --
----------------------

-- Import flobal functions
require("functions/functions")


--------------
-- Accounts --
--------------
  
-- Load email accounts data (global: accounts)
require("data/accounts")

catchall = create_account(accounts[1])
personal = create_account(accounts[2])
business = create_account(accounts[3])

accounts = {personal, business, catchall}


---------------------
-- Email addresses --
---------------------

-- Load email address lists (global: contacts)
require("data/address_book")


------------------
-- Rule Modules --
------------------

require("functions/triage")
require("functions/consolidate")
require("functions/sweep")
require("functions/organise")
require("functions/clean")
require("functions/junk")


--------------
-- Sequence --
--------------

function filter(accounts, account)

 
  announce("* Filtering starting *")
  
  status_report(accounts)
  triage(account)
  consolidate(account)
  sweep(account)
  organise(account)
  clean(account)
  junk(account)
  announce("* Filtering complete *")

end


-------------
-- Execute --
-------------

repeat

  filter(accounts, business)
  
until not(business.INBOX:enter_idle())