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

catchall = init_account(accounts[1])
personal = init_account(accounts[2])

--[[ Get a list of the available mailboxes and folders
mailboxes, folders = catchall:list_all()

-- Get a list of the subscribed mailboxes and folders
mailboxes, folders = catchall:list_subscribed()
]]--

---------------
-- Mailboxes --
---------------

-- Get the status of a mailbox
catchall.INBOX:check_status()
personal.INBOX:check_status()


---------------------
-- Email addresses --
---------------------

-- Load email address lists (global: contacts)
require("address_book")

-----------
-- Rules --
-----------

require("consolidate")
-- require("organise")
-- require("clean")