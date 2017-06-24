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


function merge(tables_in, table_out)

  if (table_out == nil) then
    table_out = {}
  end
  
  -- If tables_in is empty, return an empty table
  if (tables_in == nil) then
    return table_out
  end
  
  for _, table_entry in pairs(tables_in) do
  
    if (type(table_entry) == "table") then
      
      merge(table_entry, table_out)
      
    elseif (table_entry == nil) then
    
    elseif (not(contains(table_out, table_entry))) then
      
      table.insert(table_out, table_entry)
      
    end
    
  end
  
  return table_out
  
end


function get_filter_addresses(filter, from, to)

  if (from == nil) then
    from = true
  end
  
  if (to == nil) then
    to = true
  end
  
  if (from ~= true and from ~= false) then
    print("! Error: invalid value. The value of \'from\' must be either true or false.")
  end
  
  if (to ~= true and to ~= false) then
    print("! Error: invalid value. The value of \'to\' must be either true or false.")
  end
  
  local filter_addresses = {
    from = {},
    to = {}
  }
  
  if (from == true and filter.from) then
    filter_addresses.from = merge(filter.from)
  end
  
  if (to == true and filter.to) then
    filter_addresses.to = merge(filter.to)
  end
  
  return filter_addresses  

end


function get_group_addresses(group, from, to)

  if (from == nil) then
    from = true
  end
  
  if (to == nil) then
    to = true
  end
  
  if (from ~= true and from ~= false) then
    print("! Error: invalid value. The value of \'from\' must be either true or false.")
  end
  if (to ~= true and to ~= false) then
    print("! Error: invalid value. The value of \'to\' must be either true or false.")
  end
  
  local all_addresses = {
    from = {},
    to = {}
  }
  
  --[[
    Add the group's default list of addresses
    to the list being built.
  ]]--
  if (from == true and group.from) then
    all_addresses.from = group.from
  end
  
  if (to == true and group.to) then
    all_addresses.to = group.to  
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
    
      local filter_addresses = get_filter_addresses(filter, from, to)
              
      if (from == true and filter_addresses.from) then
        all_addresses.from = merge(all_addresses.from, filter_addresses.from)
      end
      
      if (to == true and filter_addresses.to) then
        all_addresses.to = merge(all_addresses.to, filter_addresses.to)
      end

    end

  end
  
  return all_addresses

end


function get_keywords(keywords_in)
  
  -- Flatten the list so that any reference keyword lists are merged in.   
  return merge(keywords_in)

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
