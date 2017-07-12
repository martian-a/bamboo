---------------------
-- Email Addresses --
---------------------

-- Properties and methods relating to logging.
log = {}

-- Properties and methods relating to the log file.
log.file = {
  
  -- The name of the log file.
  name = nil,
  
  -- A reference to the log file.
  instance = nil,
  
  --- Open the log file for this session.
  -- @return A file object. The opened log file instance.
  open = function()
      
    if (log.file.instance == nil) then
      -- There is currently no reference to an instance saved
      
      -- Open the log file in write mode.
      log.file.instance = io.open(log.file.name, "w")
            
    else
      -- A reference to an instance is already saved.
      
      -- Open the log file in append mode.
      log.file.instance = io.open(log.file.name, "a")

    end
    
    return log.file.instance  
  end,
  
  --- Close the log file for this session.
  -- The next time the log file is written to, the contents will be overwritten.
  close = function()
   
    log.file.instance = nil
  
  end
  
}

--- Write a message to the info log file instance
-- @param message A string.  The message to write.
log.info = function(message) 

  -- Open the log file.
  local file = log.file:open()

  if (file ~= nil) then
    -- The log file is ready for writing.
    
    -- Write the message
    file:write(message .. "\n")
    
    -- Close the stream (but don't end this log session).
    io.close(file)
    
  else
    -- The log file isn't ready for writing.
    
    -- Record an error.
    io.stderr:write("! Error ! Unable to open log file for writing.\n")
    
    -- Print the message that was supposed to be logged.
    print(message)
    
  end
  
end


--- Write a message to the error log file instance
-- @param message A string.  The message to write.
log.error = function(message) 
  
  -- Write the message in the info log
  log.info(message)
  
  -- Write the message in the error log.
  io.stderr:write("! Error ! " .. message .. "\n")

end


return log