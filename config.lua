-------------
-- Options --
-------------

options.timeout = 120
options.subscript = true

-- If a target folder doesn't exist, create it
options.create = true

-- Auto-subscribe to any new folder that's created
options.subscribe = true

-- Ignore certificate mismatches :(
options.certificates = false

-- Import functions
require("functions")


--------------
-- Accounts --
--------------

-- Load email accounts data (global: accounts)
require("accounts")

catchall = create_account(accounts[1])
personal = create_account(accounts[2])
business = create_account(accounts[3])

accounts = {personal, business, catchall}

--[[ Get a list of the available mailboxes and folders
mailboxes, folders = catchall:list_all()

-- Get a list of the subscribed mailboxes and folders
mailboxes, folders = catchall:list_subscribed()
]]--

---------------
-- Mailboxes --
---------------

-- Get the status of a mailbox
for _, account in ipairs(accounts) do
  account.INBOX:check_status()
end

---------------------
-- Email addresses --
---------------------

-- Load email address lists (global: contacts)
require("address_book")

-----------
-- Rules --
-----------

require("triage")
require("consolidate")
require("sweep")
require("organise")
require("clean")
require("junk")

print("== Filtering complete ==")