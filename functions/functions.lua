---------------
-- Functions --
---------------


function status_report(accounts)

  -- Get the status of a mailbox
  for _, account in ipairs(accounts) do
    account.INBOX:check_status()
  end

end


function get_account(id)

  local account = nil
  if (id ~= nil) then
    for _, candidate in pairs(accounts) do
      if (candidate.id == id) then
        return candidate
      end
    end
  end

  return account
end


function create_account(data)
  print("Creating " .. data.name)
  local account = IMAP {
    server = data.server,
    username = data.username,
    ssl = data.ssl,
    password = data.password
  }
  
  account.id = data.id
  account.name = data.name
  account.clean = data.clean
  account.sweep = data.sweep
  
  return account
end


function flag_messages(account, messages, flag)

  if (flag == nil) then
    flag = "Flagged"
  end

  messages:add_flags({flag})
  messages:mark_flagged()

end


function folder_exists(account, folder)

  local result = account:list_all('', folder)

  if (#result > 0) then
    return true
  end

  return false
end


function contains(table, value)
  
  -- If the table is empty, it can't contain the value
  if (table == nil) then
    return false
  end
  
  for _, entry in ipairs(table) do
    if entry == value then
      return true
    end
  end

  return false
end


function get_group_addresses(group)

  local all_addresses = {}

  --[[
    Add the group's default list of addresses
    to the list being built.
  ]]--
  if (group.addresses) then

    all_addresses = group.addresses
    
  end  

  --[[
    Add all email addresses that are listed
    in any of the group's filters.
  ]]--
  if (group.filters) then

    local group_filters = group.filters

    --[[
      Check each of the group's filters
      for addresses.
    ]]--
    for _, filter in ipairs(group.filters) do

      if (filter.addresses) then
        
        -- Add any new addresses listed in the filter
        for _, address in ipairs(filter.addresses) do

          if (not(contains(all_addresses, address))) then
            table.insert(all_addresses, address)
          end

        end
        
      end

    end

  end

  return all_addresses

end


function size(table)

  local count = 0
  for _ in pairs(table) do
    count = count + 1
  end
  
  return count
end


function announce(message)

  print("\n\n== " .. message .. " ==\n")
  
end
