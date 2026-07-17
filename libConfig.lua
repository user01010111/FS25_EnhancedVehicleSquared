-- Enhanced Vehicle Squared configuration library for Farming Simulator 22+
--
-- Maintained by user01010111 with Enhanced Vehicle Squared contributors.
-- See LICENSE and ATTRIBUTION.md.
--





local myName = "libConfig"

libConfig = {}
libConfig.__index = libConfig

setmetatable(libConfig, {
  __call = function (cls, ...)
  local self = setmetatable({}, cls)

  self.debug = 0
  self:new(...)

  return self
  end,
})



function libConfig:new(myName, configVersionCurrent, configVersionOld)
  if self.debug > 0 then print("-> libConfig: new()") end

  self.myName = myName
  self.configVersionCurrent = configVersionCurrent
  self.configVersionOld     = configVersionOld


  self.modDirectory      = g_currentModDirectory
  self.settingsDirectory = getUserProfileAppPath() .. "modSettings/"
  self.confDirectory     = self.settingsDirectory .. self.myName .. "/"


  self.dataDefault = {}
  self.dataCurrent = {}

  -- Per-load migration state selects the current file first and retires legacy
  -- data only after the replacement is saved and reopened successfully.

  self.legacyCleanupFile = nil
  self.migrationSourceFile = nil
  self.currentConfigUnreadable = false
  self.reportedWarnings = {}
  self.fileAccessAllowed = true
  self.fileAccessPolicySet = false
end



function libConfig:setDebug(dbg)
  self.debug = dbg or 0
end



function libConfig:clearConfig()
  self.dataDefault = {}
  self.dataCurrent = {}
end



function libConfig:setFileAccessAllowed(allowed)
  self.fileAccessAllowed = allowed ~= false
  self.fileAccessPolicySet = true
end



function libConfig:getFileAccessAllowed()
  if self.fileAccessPolicySet then
    return self.fileAccessAllowed ~= false
  end
  -- Before a mission sets policy, the late dedicated global is a defensive
  -- fallback. A later client mission can explicitly re-enable file access.

  return self.fileAccessAllowed ~= false and g_dedicatedServerInfo == nil
end



function libConfig:copyValue(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for key, item in pairs(value) do
    result[key] = item
  end
  return result
end



function libConfig:getConfigFilename(version)
  if version == nil then
    return nil
  end

  local versionType = type(version)
  if versionType ~= "number" and versionType ~= "string" then
    return nil
  end
  if versionType == "number" and
     (version ~= version or version == math.huge or version == -math.huge) then
    return nil
  end

  local versionText = tostring(version)
  if versionText == "" or string.find(versionText, "[/\\]") ~= nil then
    return nil
  end
  return self.confDirectory .. self.myName .. "_v" .. versionText .. ".xml"
end



function libConfig:warningOnce(key, message)
  if self.reportedWarnings[key] then
    return
  end
  self.reportedWarnings[key] = true

  local text = myName .. " (" .. tostring(self.myName) .. "): " .. message
  if Logging ~= nil and Logging.warning ~= nil then
    Logging.warning(text)
  else
    print("Warning: " .. text)
  end
end



function libConfig:isXMLHandleValid(xml)
  return xml ~= nil and xml ~= 0
end



function libConfig:releaseXMLHandle(xml)
  if self:isXMLHandleValid(xml) then
    delete(xml)
  end
end



function libConfig:loadConfigFile(filename, applyValues, strictValues)
  if not self:getFileAccessAllowed() then
    return false
  end
  local loaded, xml = pcall(loadXMLFile, self.myName, filename)
  if not loaded or not self:isXMLHandleValid(xml) then
    return false
  end

  local rootChecked, hasExpectedRoot = pcall(hasXMLProperty, xml, self.myName)
  if not rootChecked or not hasExpectedRoot then
    self:releaseXMLHandle(xml)
    return false
  end

  local values = {}
  local parsed = pcall(function()
    local pos = {}
    local sortedKeys = self:getKeysSortedByValue(
      self.dataCurrent,
      function(a, b)
        if a.section == b.section then
          return a.name < b.name
        end
        return a.section < b.section
      end)

    for _, key in ipairs(sortedKeys) do
      local data = self.dataCurrent[key]
      local group = data.section
      if pos[group] == nil then
        pos[group] = 0
      end
      local groupNameTag = string.format("%s.%s(%d)", self.myName, group, pos[group])
      if data.newLine then
        pos[group] = pos[group] + 1
      end

      local property = groupNameTag .. "#" .. data.name
      local propertyExists = hasXMLProperty(xml, property)
      local value = nil
      if data.typ == "float" then
        value = getXMLFloat(xml, property)
        if value ~= nil and
           (value ~= value or value == math.huge or value == -math.huge) then
          error("configuration float is not finite")
        end
        if strictValues and
           (value == nil or value ~= value or
            math.abs(value - tonumber(data.value)) > 0.000001) then
          error("persisted float does not match")
        end
      elseif data.typ == "int" then
        value = getXMLInt(xml, property)
        if strictValues and
           (value == nil or value ~= math.floor(tonumber(data.value))) then
          error("persisted integer does not match")
        end
      elseif data.typ == "bool" then
        value = getXMLBool(xml, property)
        if strictValues and value ~= data.value then
          error("persisted boolean does not match")
        end
      elseif data.typ == "table" then
        local storedValue = getXMLString(xml, property)
        if strictValues and storedValue ~= table.concat(data.value, ",") then
          error("persisted table does not match")
        end
        if storedValue ~= nil then
          value = self:splitter(storedValue, ",")
        end
      elseif strictValues then
        error("unsupported configuration value type")
      end

      -- Missing attributes inherit defaults. Present attributes that typed
      -- getters cannot parse are malformed and must not be rewritten.

      if propertyExists and value == nil then
        error("configuration attribute has an invalid type")
      end

      if value == nil then
        value = self:copyValue(data.value)
      end
      values[key] = value
    end
  end)

  -- XML handles are engine resources and must be released after parser errors.

  self:releaseXMLHandle(xml)
  if not parsed then
    return false
  end

  if applyValues then
    for key, value in pairs(values) do
      self.dataCurrent[key].value = value
    end
  end
  return true
end



function libConfig:discardFailedMigrationTarget()
  if not self:getFileAccessAllowed() then
    return
  end
  if self.migrationSourceFile == nil or self.confFile == nil or
     self.migrationSourceFile == self.confFile then
    return
  end
  if not fileExists(self.confFile) then
    return
  end

  if type(deleteFile) == "function" then
    pcall(deleteFile, self.confFile)
  end
  if fileExists(self.confFile) then
    self:warningOnce(
      "partialMigrationCleanupFailed:" .. self.confFile,
      "a failed migration left an unreadable current file; legacy configuration remains at " ..
        self.migrationSourceFile)
  end
end



function libConfig:addConfigValue(section, name, typ, value, newLine)
  if self.debug > 0 then print("-> "..myName.." ("..self.myName..") addConfigValue()") end
  if self.debug > 1 then print("--> section: "..section..", name: "..name..", typ: "..typ..", value: "..tostring(value)) end


  local newData = {}
  newData.section = section
  newData.typ     = typ
  newData.name    = name
  newData.value   = value
  newData.newLine = newLine or false

  local defaultValue = value
  if type(value) == "table" then
    defaultValue = {}
    for key, item in pairs(value) do
      defaultValue[key] = item
    end
  end

  -- Defaults and current values must remain independent objects.

  table.insert(self.dataDefault, {
    section = newData.section,
    typ = newData.typ,
    name = newData.name,
    value = defaultValue,
    newLine = newData.newLine
  })
  table.insert(self.dataCurrent, newData)

  if self.debug > 2 then print(DebugUtil.printTableRecursively(self.dataCurrent, 0, 0, 3)) end
end



function libConfig:getConfigValue(section, name)
  if self.debug > 0 then print("-> "..myName.." ("..self.myName..") getConfigValue()") end
  if self.debug > 1 then print("--> section: "..section..", name: "..name) end


  for _, data in pairs(self.dataCurrent) do
    if data.section == section and data.name == name then
      if self.debug > 1 then print("---> typ: "..data.typ..", value: "..tostring(data.value)) end
      return(data.value)
    end
  end

  return(nil)
end



function libConfig:setConfigValue(section, name, value, deferWrite)
  if self.debug > 0 then print("-> "..myName.." ("..self.myName..") setConfigValue()") end
  if self.debug > 1 then print("--> section: "..section..", name: "..name..", value: "..tostring(value)) end


  for _, data in pairs(self.dataCurrent) do
    if data.section == section and data.name == name then
      data.value = value
    end
  end

  -- Callers that do not opt into batching retain immediate persistence.

  if not deferWrite then
    self:writeConfig()
  end

  if self.debug > 2 then print(DebugUtil.printTableRecursively(self.dataCurrent, 0, 0, 3)) end
end



function libConfig:readConfig()
  if self.debug > 0 then print("-> "..myName.." ("..self.myName..") readConfig()") end

  if not self:getFileAccessAllowed() then
    return false, "disabled", false
  end

  self.legacyCleanupFile = nil
  self.migrationSourceFile = nil
  self.currentConfigUnreadable = false

  local currentFile = self:getConfigFilename(self.configVersionCurrent)
  local oldFile = self:getConfigFilename(self.configVersionOld)
  if currentFile == nil then
    self:warningOnce("invalidCurrentVersion", "cannot use configuration files because the current version is not set")
    return false, "invalidVersion", false
  end

  -- A present current file is authoritative. If malformed, preserve it and use
  -- clean defaults without resurrecting legacy state.
  if fileExists(currentFile) then
    self.confFile = currentFile
    if not self:loadConfigFile(currentFile, true) then
      self.currentConfigUnreadable = true
      self:warningOnce(
        "unreadableCurrent:" .. currentFile,
        "current configuration is unreadable; using defaults without overwriting " .. currentFile)
      return false, "currentUnreadable", false
    end

    if oldFile ~= nil and oldFile ~= currentFile and fileExists(oldFile) then
      self.legacyCleanupFile = oldFile
    end
    return true, "current", true
  end

  -- Legacy data is a one-time fallback only when the current destination differs.

  if oldFile ~= nil and oldFile ~= currentFile and fileExists(oldFile) then
    self.confFile = oldFile
    if not self:loadConfigFile(oldFile, true) then
      self:warningOnce(
        "unreadableOld:" .. oldFile,
        "legacy configuration is unreadable; using defaults and retaining " .. oldFile)
      return false, "oldUnreadable", false
    end

    self.legacyCleanupFile = oldFile
    self.migrationSourceFile = oldFile
    local migrated, migrationStatus = self:writeConfig()
    if migrated then
      if migrationStatus == "cleanupFailed" then
        return true, "migratedCleanupFailed", false
      end
      return true, "migrated", false
    end
    return true, "migrationWriteFailed", false
  end

  self.confFile = currentFile
  return false, "missing", true
end



function libConfig:writeConfig()
  if self.debug > 0 then print("-> "..myName.." ("..self.myName..") writeConfig()") end

  if not self:getFileAccessAllowed() then
    return false, "disabled"
  end

  if self.currentConfigUnreadable then
    self:warningOnce(
      "blockedUnreadableCurrent",
      "configuration writes are disabled for this load to preserve the unreadable current file")
    return false, "currentUnreadable"
  end

  self.confFile = self:getConfigFilename(self.configVersionCurrent)
  if self.confFile == nil then
    self:warningOnce("invalidCurrentWriteVersion", "cannot write configuration because the current version is not set")
    return false, "invalidVersion"
  end
  if self.debug > 1 then print("--> confFile: "..self.confFile) end


  createFolder(self.settingsDirectory)
  createFolder(self.confDirectory);

  local created, xml = pcall(createXMLFile, self.myName, self.confFile, self.myName)
  if not created or not self:isXMLHandleValid(xml) then
    self:discardFailedMigrationTarget()
    self:warningOnce("createFailed:" .. self.confFile, "could not create configuration " .. self.confFile)
    return false, "createFailed"
  end

  local wrote, saved = pcall(function()
    local pos = {}
    local sortedKeys = self:getKeysSortedByValue(
      self.dataCurrent,
      function(a, b)
        if a.section == b.section then
          return a.name < b.name
        end
        return a.section < b.section
      end)

    for _, key in ipairs(sortedKeys) do
      local data = self.dataCurrent[key]
      local group = data.section
      if pos[group] == nil then
        pos[group] = 0
      end
      local groupNameTag = string.format("%s.%s(%d)", self.myName, group, pos[group])
      if data.newLine then
        pos[group] = pos[group] + 1
      end
      if data.typ == "float" then
        setXMLFloat(xml, groupNameTag .. "#" .. data.name, tonumber(data.value))
      elseif data.typ == "int" then
        setXMLInt(xml, groupNameTag .. "#" .. data.name, math.floor(tonumber(data.value)))
      elseif data.typ == "bool" then
        setXMLBool(xml, groupNameTag .. "#" .. data.name, data.value)
      elseif data.typ == "table" then
        setXMLString(xml, groupNameTag .. "#" .. data.name, table.concat(data.value, ","))
      end
    end

    return saveXMLFile(xml)
  end)
  self:releaseXMLHandle(xml)

  if not wrote or saved ~= true then
    self:discardFailedMigrationTarget()
    self:warningOnce("saveFailed:" .. self.confFile, "could not save configuration; any legacy file was retained")
    return false, "saveFailed"
  end

  -- Saving is successful only when the file exists and strict reopening matches.

  if not fileExists(self.confFile) or not self:loadConfigFile(self.confFile, false, true) then
    self:discardFailedMigrationTarget()
    self:warningOnce("verifyFailed:" .. self.confFile, "could not verify saved configuration; any legacy file was retained")
    return false, "verifyFailed"
  end

  local cleanupFile = self.legacyCleanupFile
  if cleanupFile ~= nil and cleanupFile ~= self.confFile and fileExists(cleanupFile) then
    local deleted = false
    if type(deleteFile) == "function" then
      local deleteCalled = pcall(deleteFile, cleanupFile)
      deleted = deleteCalled and not fileExists(cleanupFile)
    end
    if not deleted then
      self:warningOnce(
        "cleanupFailed:" .. cleanupFile,
        "current configuration was saved, but legacy cleanup failed for " .. cleanupFile)
      -- The verified current file remains authoritative even if legacy cleanup fails.

      self.legacyCleanupFile = nil
      self.migrationSourceFile = nil
      return true, "cleanupFailed"
    end
  end
  self.legacyCleanupFile = nil
  self.migrationSourceFile = nil

  if self.debug > 2 then print(DebugUtil.printTableRecursively(self.dataCurrent, 0, 0, 3)) end
  return true, "written"
end



function libConfig:getKeysSortedByValue(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  return keys
end



function libConfig:splitter(str, pat, limit)
  local t = {}
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t, cap)
    end

    last_end = e+1
    s, e, cap = str:find(fpat, last_end)

    if limit ~= nil and limit <= #t then
      break
    end
  end

  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end

  return t
end
