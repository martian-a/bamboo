-------------
-- Options --
-------------

-- Provide feedback on actions applied by Imapfilter
options.info = true

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

-- Return from IDLE on any change to Inbox
options.wakeonany = true

-- The time in minutes before terminating and re-issuing the IDLE command
options.keepalive = 9

-------------
-- Logging --
-------------

-- Import log settings
log = require("functions/log")

-- Set the default log file name
log.file.name = "business.latest.log"


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
primary_account = business

------------------
-- Rule Modules --
------------------

require("functions/triage")
require("functions/consolidate")
require("functions/organise")
require("functions/sweep")
require("functions/clean")
require("functions/junk")


-------------
-- Execute --
-------------

repeat
  dofile("functions/sequence.lua")
  filter(accounts, primary_account)
  log.file:close()
until not(primary_account.INBOX:enter_idle())