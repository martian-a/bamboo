--------------------------
-- Consolidate Messages --
--------------------------

print(" \n\n== Consolidating ==\n")

function consolidate(account, group) 

  if (account == nil) then
    print("! Error: account not specified.")
    return
  elseif (group == nil) then
    print("! Error: group not specified.")
    return
  elseif (group.addresses == nil) then
    print("! Error: no addresses specified.")
    return
  elseif (group.consolidate == nil or group.consolidate.destination == nil) then
    print("! Error: destination account not specified.")
    return
  end
  
  print("Consolidating " .. group.name .. " in " .. account.name .. ".")
  local all_messages = account.INBOX:select_all()
  print(#all_messages .. " messages to check.")
  
  local addresses = group.addresses
  print(#addresses .. " addresses to check.")
  
  local messages = {}
  for index, address in ipairs(addresses) do
    print("- checking " .. address)
    local related = to_from(all_messages, address)
    print("...found " .. #related .. " messages.")
    messages = messages + related
    all_messages = all_messages - related
  end

  if (#messages > 0) then
    
    if (group.consolildate.star == nil or group.consolidate.star == false) then
      -- don't flag messages
    elseif (not(group.consolidate.star == true)) then
      print("! Error: the value of consolidate.star must be either true or false")
    else
      account:add_flags({"Flagged"}, messages)
      print(#messages .. " flagged.")
    end
      
    -- Move messages related to family to my personal account
    messages:move_messages(group.consolidate.destination["INBOX"])
  else
    print("0 messages to move.")
  end
  
end  

consolidate(catchall, contacts.family)
consolidate(catchall, contacts.friends)
consolidate(personal, contacts.priority)