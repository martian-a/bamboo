---------------
-- Functions --
---------------


function init_account(data)
  print("Initialising " .. data.name)
  local account = IMAP {
    server = data.server,
    username = data.username,
    ssl = data.ssl,
    password = data.password
  }
  account.name = data.name
  return account
end


function to_from(messages, address)
  local related = 
      messages:contain_from(address)
    + messages:contain_cc(address)
    + messages:contain_bcc(address)
    + messages:contain_to(address)
  return related
end