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


----------------
-- Controller --
----------------

function filter()

  -- Import flobal functions
  dofile("functions.lua")

  announce("* Filtering starting *")


  --------------
  -- Accounts --
  --------------
  
  -- Load email accounts data (global: accounts)
  dofile("accounts.lua")
  
  catchall = create_account(accounts[1])
  personal = create_account(accounts[2])
  business = create_account(accounts[3])
  
  accounts = {personal, business, catchall}

  
  ---------------------
  -- Email addresses --
  ---------------------
  
  -- Load email address lists (global: contacts)
  dofile("address_book.lua")


  --------------
  -- Rules --
  --------------

  dofile("triage.lua")
  dofile("consolidate.lua")
  dofile("sweep.lua")
  dofile("organise.lua")
  dofile("clean.lua")
  dofile("junk.lua")

  
  --------------
  -- Sequence --
  --------------
  
  status_report(accounts)
  triage(accounts)
  consolidate(accounts)
  sweep(accounts)
  organise(accounts)
  clean(accounts)
  junk(accounts)
  announce("* Filtering complete *")

end


---------------
-- Daemonize --
---------------

become_daemon(600, filter(), true, true)