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


function flag_messages(account, messages, flag)

  if (flag == nil) then
    flag = "Flagged"
  end

  account:add_flags({flag}, messages)
  account:mark_flagged()
  print(#messages .. " flagged.")

end


function folder_exists(account, folder)
  
  local result = account:list_all('', folder)
  
  if (#result > 0) then
    return true
  end
  
  return false
end