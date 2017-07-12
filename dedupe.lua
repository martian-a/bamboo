-------------
-- Options --
-------------

-- Time to wait (in seconds) for the mail server to respond.
options.timeout = 120

-- Quiet (no summary)
options.info = false

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

-------------
-- Logging --
-------------

-- Import log settings
log = require("functions/log")

-- Set the default log file name
log.file.name = "dedupe.latest.log"


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


------------------
-- Rule Modules --
------------------

require("functions/duplicates")


-------------
-- Execute --
-------------

duplicates(catchall, "Stasis", "temp_dedupe")
log.file:close()