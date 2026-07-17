-- Proprietary-free regression checks for libConfig's production read/write
-- paths.  The GIANTS XML/file API is represented by an in-memory fixture so
-- failures and resource lifetimes are deterministic.

local function assertEqual(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
  end
end

local function assertTrue(value, label)
  if not value then error(label .. ": expected true", 2) end
end

local function assertFalse(value, label)
  if value then error(label .. ": expected false", 2) end
end

local function copyTable(value)
  local result = {}
  for key, item in pairs(value or {}) do result[key] = item end
  return result
end

local state
local function resetEngine()
  state = {
    files = {},
    calls = {
      fileExists = 0,
      loadXMLFile = 0,
      createFolder = 0,
      createXMLFile = 0,
      hasXMLProperty = 0,
      getXML = 0,
      setXML = 0,
      saveXMLFile = 0,
      deleteFile = 0,
    },
    opened = 0,
    released = 0,
    failCreate = false,
    failSave = false,
    failDelete = false,
    failGetter = false,
    failSetter = false,
    writePartialOnSaveFailure = false,
    corruptSavedValues = false,
    events = {},
  }
  Logging.warnings = {}
end

debug = 0
g_currentModDirectory = "./"
g_dedicatedServerInfo = nil
Logging = { warnings = {} }
function Logging.warning(message) table.insert(Logging.warnings, message) end
function getUserProfileAppPath() return "/profile/" end

function fileExists(filename)
  state.calls.fileExists = state.calls.fileExists + 1
  table.insert(state.events, "exists:" .. tostring(filename))
  return state.files[filename] ~= nil
end

function loadXMLFile(_, filename)
  state.calls.loadXMLFile = state.calls.loadXMLFile + 1
  table.insert(state.events, "load:" .. tostring(filename))
  local file = state.files[filename]
  if file == nil or file.malformed then return 0 end
  state.opened = state.opened + 1
  return {
    filename = filename,
    values = copyTable(file.values),
    invalidKeys = copyTable(file.invalidKeys),
    hasRoot = file.hasRoot ~= false,
    rootName = file.rootName or "ConfigTest",
    released = false,
  }
end

function hasXMLProperty(xml, property)
  state.calls.hasXMLProperty = state.calls.hasXMLProperty + 1
  if property == xml.rootName then return xml.hasRoot end
  return xml.values[property] ~= nil or xml.invalidKeys[property] == true
end

function createFolder(_)
  state.calls.createFolder = state.calls.createFolder + 1
  return true
end

function createXMLFile(_, filename, rootName)
  state.calls.createXMLFile = state.calls.createXMLFile + 1
  if state.failCreate then return 0 end
  state.opened = state.opened + 1
  return {
    filename = filename,
    values = {},
    hasRoot = true,
    rootName = rootName,
    released = false,
  }
end

local function getValue(xml, key)
  state.calls.getXML = state.calls.getXML + 1
  if state.failGetter then error("injected XML getter failure") end
  return xml.values[key]
end
getXMLFloat = getValue
getXMLInt = getValue
getXMLBool = getValue
getXMLString = getValue

local function setValue(xml, key, value)
  state.calls.setXML = state.calls.setXML + 1
  if state.failSetter then error("injected XML setter failure") end
  xml.values[key] = value
end
setXMLFloat = setValue
setXMLInt = setValue
setXMLBool = setValue
setXMLString = setValue

function saveXMLFile(xml)
  state.calls.saveXMLFile = state.calls.saveXMLFile + 1
  table.insert(state.events, "save:" .. tostring(xml.filename))
  if state.failSave then
    if state.writePartialOnSaveFailure then
      state.files[xml.filename] = { malformed = true }
    end
    return false
  end
  local storedValues = state.corruptSavedValues and {} or copyTable(xml.values)
  state.files[xml.filename] = {
    values = storedValues,
    hasRoot = true,
    rootName = xml.rootName,
  }
  return true
end

function delete(xml)
  assertFalse(xml.released, "XML handle double release")
  xml.released = true
  state.released = state.released + 1
end

function deleteFile(filename)
  state.calls.deleteFile = state.calls.deleteFile + 1
  table.insert(state.events, "deleteFile:" .. tostring(filename))
  if state.failDelete then return false end
  state.files[filename] = nil
  return true
end

Utils = {
  getNoNil = function(value, defaultValue)
    if value == nil then return defaultValue end
    return value
  end,
}

dofile("libConfig.lua")

local currentFile = "/profile/modSettings/ConfigTest/ConfigTest_v1.xml"
local oldFile = "/profile/modSettings/ConfigTest/ConfigTest_v0.xml"

local function values(flag, ratio, count, items)
  return {
    ["ConfigTest.section(0)#flag"] = flag,
    ["ConfigTest.section(0)#ratio"] = ratio,
    ["ConfigTest.section(0)#count"] = count,
    ["ConfigTest.section(0)#items"] = table.concat(items, ","),
  }
end

local function install(filename, flag, ratio, count, items)
  state.files[filename] = { values = values(flag, ratio, count, items) }
end

local function newConfig(currentVersion, oldVersion)
  local config = libConfig("ConfigTest", currentVersion, oldVersion)
  config:addConfigValue("section", "flag", "bool", true)
  config:addConfigValue("section", "ratio", "float", 1.5)
  config:addConfigValue("section", "count", "int", 2)
  config:addConfigValue("section", "items", "table", { "default", "items" })
  return config
end

local function assertConfig(config, flag, ratio, count, firstItem, label)
  assertEqual(config:getConfigValue("section", "flag"), flag, label .. " bool")
  assertEqual(config:getConfigValue("section", "ratio"), ratio, label .. " float")
  assertEqual(config:getConfigValue("section", "count"), count, label .. " int")
  assertEqual(config:getConfigValue("section", "items")[1], firstItem, label .. " table")
end

local function assertBalanced(label)
  assertEqual(state.released, state.opened, label .. " XML handles")
end

local function assertTablesEqual(actual, expected, label)
  for key, value in pairs(expected) do
    assertEqual(actual[key], value, label .. " value " .. tostring(key))
  end
  for key in pairs(actual) do
    assertTrue(expected[key] ~= nil, label .. " unexpected key " .. tostring(key))
  end
end

-- No files loads defaults and permits the normal startup write.
resetEngine()
do
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "missing loaded")
  assertEqual(status, "missing", "missing status")
  assertTrue(shouldWrite, "missing startup write")
  assertConfig(config, true, 1.5, 2, "default", "missing defaults")
  assertTrue(config:writeConfig(), "missing defaults write")
  assertTrue(state.files[currentFile] ~= nil, "missing current created")
  assertEqual(state.calls.deleteFile, 0, "missing legacy delete")
  assertBalanced("missing")
end

-- A usable current file is authoritative.
resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current", "value" })
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "current loaded")
  assertEqual(status, "current", "current status")
  assertTrue(shouldWrite, "current merged write")
  assertConfig(config, false, 3.25, 7, "current", "current values")
  assertTrue(config:writeConfig(), "current write")
  assertEqual(state.calls.deleteFile, 0, "current no legacy delete")
  assertBalanced("current")
end

-- When both files exist, v1 wins even when v0 conflicts.
resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current" })
  install(oldFile, true, 9.5, 99, { "stale" })
  local config = newConfig(1, 0)
  local loaded, status = config:readConfig()
  assertTrue(loaded, "both loaded")
  assertEqual(status, "current", "both current status")
  assertConfig(config, false, 3.25, 7, "current", "both current wins")
  assertTrue(config:writeConfig(), "both write")
  assertEqual(state.files[oldFile], nil, "both stale legacy retired")
  assertBalanced("both")
end

-- A lone usable v0 is loaded, persisted as v1, verified, and only then retired.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy", "items" })
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "legacy loaded")
  assertEqual(status, "migrated", "legacy status")
  assertFalse(shouldWrite, "legacy redundant startup write")
  assertConfig(config, false, 4.5, 8, "legacy", "legacy values")
  assertTrue(state.files[currentFile] ~= nil, "legacy current persisted")
  assertEqual(state.files[oldFile], nil, "legacy retired")
  assertEqual(state.calls.deleteFile, 1, "legacy one delete")
  local saveIndex = nil
  local verificationIndex = nil
  local deleteIndex = nil
  for index, event in ipairs(state.events) do
    if event == "save:" .. currentFile then saveIndex = index end
    if saveIndex ~= nil and event == "load:" .. currentFile then verificationIndex = index end
    if event == "deleteFile:" .. oldFile then deleteIndex = index end
  end
  assertTrue(saveIndex ~= nil and verificationIndex ~= nil and deleteIndex ~= nil,
    "legacy migration ordering events")
  assertTrue(saveIndex < verificationIndex and verificationIndex < deleteIndex,
    "legacy save/verify/delete ordering")
  assertBalanced("legacy migration")
end

-- Failed v1 persistence retains the only usable legacy copy.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  state.failSave = true
  state.writePartialOnSaveFailure = true
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "failed migration legacy loaded")
  assertEqual(status, "migrationWriteFailed", "failed migration status")
  assertFalse(shouldWrite, "failed migration redundant startup write")
  assertTrue(state.files[oldFile] ~= nil, "failed migration retained legacy")
  assertEqual(state.files[currentFile], nil, "failed migration partial current removed")
  assertEqual(state.calls.deleteFile, 1, "failed migration deletes only partial current")
  assertBalanced("failed migration")
end

-- A nominally successful save with a missing/corrupt payload is not verified
-- and therefore cannot retire v0.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  state.corruptSavedValues = true
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "corrupt migration legacy loaded")
  assertEqual(status, "migrationWriteFailed", "corrupt migration status")
  assertFalse(shouldWrite, "corrupt migration redundant startup write")
  assertTrue(state.files[oldFile] ~= nil, "corrupt migration retained legacy")
  assertEqual(state.files[currentFile], nil, "corrupt migration partial current removed")
  assertBalanced("corrupt migration")
end

-- Failed cleanup leaves both files, but the verified v1 remains authoritative.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  state.failDelete = true
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "cleanup failure loaded")
  assertEqual(status, "migratedCleanupFailed", "cleanup failure status")
  assertFalse(shouldWrite, "cleanup failure redundant startup write")
  assertTrue(state.files[oldFile] ~= nil, "cleanup failure retained old")
  assertTrue(state.files[currentFile] ~= nil, "cleanup failure retained current")

  -- Make the stale file conflict before simulating the next process load.
  state.files[oldFile].values["ConfigTest.section(0)#flag"] = true
  local reloaded = newConfig(1, 0)
  local loaded, readStatus = reloaded:readConfig()
  assertTrue(loaded, "cleanup failure reload")
  assertEqual(readStatus, "current", "cleanup failure current status")
  assertEqual(reloaded:getConfigValue("section", "flag"), false, "cleanup failure v1 wins")
  assertBalanced("cleanup failure")
end

-- Once migrated, repeated load/write cycles do not recreate or re-read v0.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  local first = newConfig(1, 0)
  local _, firstStatus = first:readConfig()
  assertEqual(firstStatus, "migrated", "idempotent first migration")
  local firstPayload = copyTable(state.files[currentFile].values)
  local deleteCount = state.calls.deleteFile
  local second = newConfig(1, 0)
  local loaded, status = second:readConfig()
  assertTrue(loaded, "idempotent current load")
  assertEqual(status, "current", "idempotent current status")
  assertTrue(second:writeConfig(), "idempotent current write")
  assertEqual(state.calls.deleteFile, deleteCount, "idempotent no repeated cleanup")
  assertEqual(state.files[oldFile], nil, "idempotent old absent")
  assertTablesEqual(state.files[currentFile].values, firstPayload, "idempotent payload")
  assertBalanced("idempotent")
end

-- An unreadable current file blocks stale-v0 fallback and all writes for the
-- load, preserving both recovery candidates and warning only once per cause.
resetEngine()
do
  state.files[currentFile] = { malformed = true }
  install(oldFile, false, 4.5, 8, { "legacy" })
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "malformed current loaded")
  assertEqual(status, "currentUnreadable", "malformed current status")
  assertFalse(shouldWrite, "malformed current startup write")
  assertConfig(config, true, 1.5, 2, "default", "malformed current defaults")
  assertEqual(state.calls.loadXMLFile, 1, "malformed current no old load")
  assertFalse(config:writeConfig(), "malformed current blocked write")
  local warningCount = #Logging.warnings
  assertFalse(config:writeConfig(), "malformed current repeated blocked write")
  assertEqual(#Logging.warnings, warningCount, "malformed current warning deduplicated")
  assertTrue(state.files[currentFile].malformed, "malformed current retained")
  assertTrue(state.files[oldFile] ~= nil, "malformed current legacy retained")
  assertBalanced("malformed current")
end

-- An unreadable legacy file leaves defaults in memory and is not retired or
-- replaced automatically.
resetEngine()
do
  state.files[oldFile] = { malformed = true }
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "malformed old loaded")
  assertEqual(status, "oldUnreadable", "malformed old status")
  assertFalse(shouldWrite, "malformed old startup write")
  assertConfig(config, true, 1.5, 2, "default", "malformed old defaults")
  assertTrue(state.files[oldFile].malformed, "malformed old retained")
  assertEqual(state.files[currentFile], nil, "malformed old no replacement")
  assertBalanced("malformed old")
end

-- A syntactically valid XML attribute with an invalid typed value is malformed,
-- not merely absent.  Current v1 still blocks fallback; legacy v0 is retained.
resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current" })
  local flagKey = "ConfigTest.section(0)#flag"
  state.files[currentFile].values[flagKey] = nil
  state.files[currentFile].invalidKeys = { [flagKey] = true }
  install(oldFile, false, 4.5, 8, { "legacy" })
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "invalid typed current loaded")
  assertEqual(status, "currentUnreadable", "invalid typed current status")
  assertFalse(shouldWrite, "invalid typed current startup write")
  assertConfig(config, true, 1.5, 2, "default", "invalid typed current defaults")
  assertEqual(state.calls.loadXMLFile, 1, "invalid typed current no old load")
  assertTrue(state.files[currentFile] ~= nil, "invalid typed current retained")
  assertTrue(state.files[oldFile] ~= nil, "invalid typed current old retained")
  assertBalanced("invalid typed current")
end

resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  local flagKey = "ConfigTest.section(0)#flag"
  state.files[oldFile].values[flagKey] = nil
  state.files[oldFile].invalidKeys = { [flagKey] = true }
  local config = newConfig(1, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "invalid typed old loaded")
  assertEqual(status, "oldUnreadable", "invalid typed old status")
  assertFalse(shouldWrite, "invalid typed old startup write")
  assertTrue(state.files[oldFile] ~= nil, "invalid typed old retained")
  assertEqual(state.files[currentFile], nil, "invalid typed old no replacement")
  assertBalanced("invalid typed old")
end

-- Repeated XML nodes use one total section/name order for reads, writes, and
-- strict verification, making newLine migrations stable on Lua 5.1.
resetEngine()
do
  state.files[oldFile] = {
    values = {
      ["ConfigTest.group(0)#a"] = true,
      ["ConfigTest.group(0)#b"] = false,
      ["ConfigTest.group(1)#c"] = true,
      ["ConfigTest.group(1)#d"] = false,
    },
  }
  local function groupedConfig()
    local config = libConfig("ConfigTest", 1, 0)
    config:addConfigValue("group", "d", "bool", true)
    config:addConfigValue("group", "b", "bool", true, true)
    config:addConfigValue("group", "a", "bool", false)
    config:addConfigValue("group", "c", "bool", false)
    return config
  end
  local config = groupedConfig()
  local loaded, status, shouldWrite = config:readConfig()
  assertTrue(loaded, "grouped legacy loaded")
  assertEqual(status, "migrated", "grouped legacy status")
  assertFalse(shouldWrite, "grouped legacy redundant write")
  assertEqual(config:getConfigValue("group", "a"), true, "grouped a")
  assertEqual(config:getConfigValue("group", "b"), false, "grouped b")
  assertEqual(config:getConfigValue("group", "c"), true, "grouped c")
  assertEqual(config:getConfigValue("group", "d"), false, "grouped d")
  assertEqual(state.files[oldFile], nil, "grouped old retired")

  local reloaded = groupedConfig()
  local currentLoaded, currentStatus = reloaded:readConfig()
  assertTrue(currentLoaded, "grouped current reload")
  assertEqual(currentStatus, "current", "grouped current status")
  assertEqual(reloaded:getConfigValue("group", "a"), true, "grouped reload a")
  assertEqual(reloaded:getConfigValue("group", "b"), false, "grouped reload b")
  assertEqual(reloaded:getConfigValue("group", "c"), true, "grouped reload c")
  assertEqual(reloaded:getConfigValue("group", "d"), false, "grouped reload d")
  assertBalanced("grouped migration")
end

-- Equal old/current versions are one file, never a cleanup target.
resetEngine()
do
  install(currentFile, false, 3.25, 7, { "same" })
  local config = newConfig(1, 1)
  local loaded, status = config:readConfig()
  assertTrue(loaded, "equal version load")
  assertEqual(status, "current", "equal version status")
  assertTrue(config:writeConfig(), "equal version write")
  assertEqual(state.calls.deleteFile, 0, "equal version no delete")
  assertTrue(state.files[currentFile] ~= nil, "equal version current retained")
  assertBalanced("equal version")
end

-- Nil/unusual version inputs do not touch or delete a legacy file.
resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  local config = newConfig(nil, 0)
  local loaded, status, shouldWrite = config:readConfig()
  assertFalse(loaded, "nil current load")
  assertEqual(status, "invalidVersion", "nil current status")
  assertFalse(shouldWrite, "nil current startup write")
  assertFalse(config:writeConfig(), "nil current write")
  assertEqual(state.calls.fileExists, 0, "nil current no existence check")
  assertEqual(state.calls.createFolder, 0, "nil current no folder")
  assertEqual(state.calls.deleteFile, 0, "nil current no delete")
  assertTrue(state.files[oldFile] ~= nil, "nil current old retained")
  assertBalanced("nil current")
end

resetEngine()
do
  install(oldFile, false, 4.5, 8, { "legacy" })
  local config = newConfig(false, 0)
  local loaded, status = config:readConfig()
  assertFalse(loaded, "unsupported current load")
  assertEqual(status, "invalidVersion", "unsupported current status")
  assertEqual(state.calls.fileExists, 0, "unsupported current no existence check")
  assertEqual(state.calls.deleteFile, 0, "unsupported current no delete")
  assertTrue(state.files[oldFile] ~= nil, "unsupported current old retained")
  assertBalanced("unsupported current")
end

resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current" })
  local config = newConfig(1, nil)
  local loaded, status = config:readConfig()
  assertTrue(loaded, "nil old current load")
  assertEqual(status, "current", "nil old current status")
  assertTrue(config:writeConfig(), "nil old current write")
  assertEqual(state.calls.deleteFile, 0, "nil old no delete")
  assertBalanced("nil old")
end

resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current" })
  local config = newConfig(1, {})
  local loaded, status = config:readConfig()
  assertTrue(loaded, "unsupported old current load")
  assertEqual(status, "current", "unsupported old current status")
  assertTrue(config:writeConfig(), "unsupported old current write")
  assertEqual(state.calls.deleteFile, 0, "unsupported old no delete")
  assertBalanced("unsupported old")
end

-- Getter and setter exceptions still release every valid XML entity.
resetEngine()
do
  install(currentFile, false, 3.25, 7, { "current" })
  state.failGetter = true
  local config = newConfig(1, 0)
  local loaded, status = config:readConfig()
  assertFalse(loaded, "getter failure load")
  assertEqual(status, "currentUnreadable", "getter failure status")
  assertBalanced("getter failure")
end

resetEngine()
do
  local config = newConfig(1, 0)
  config:readConfig()
  state.failSetter = true
  local written = config:writeConfig()
  assertFalse(written, "setter failure write")
  assertBalanced("setter failure")
end

-- Exercise the production loadMap role decision with the same file/XML spies.
-- This verifies that the explicit policy is installed early enough to cover
-- direct and indirect write paths.
function Class(classTable)
  return { __index = classTable }
end
Utils.overwrittenFunction = function(_, replacement) return replacement end
WheelsUtil = {
  getSmoothedAcceleratorAndBrakePedals = function(_, accelerator, brake)
    return accelerator, brake
  end,
}
dofile("FS25_EnhancedVehicle.lua")
FS25_EnhancedVehicle.sections = {
  "fuel", "dmg", "misc", "rpm", "temp", "diff", "track", "park", "odo",
}
FS25_EnhancedVehicle.hud = {}

local evCurrentFile =
  "/profile/modSettings/FS25_EnhancedVehicle/FS25_EnhancedVehicle_v1.xml"
local evOldFile =
  "/profile/modSettings/FS25_EnhancedVehicle/FS25_EnhancedVehicle_v0.xml"
local featureNames = {
  "diffIsEnabled",
  "hydraulicIsEnabled",
  "snapIsEnabled",
  "parkingBrakeIsEnabled",
  "odoMeterIsEnabled",
}

local function evFeatureValues(value)
  local result = {}
  for _, name in ipairs(featureNames) do
    result["FS25_EnhancedVehicle.global.functions(0)#" .. name] = value
  end
  return result
end

local function installEV(filename, value)
  state.files[filename] = {
    values = evFeatureValues(value),
    rootName = "FS25_EnhancedVehicle",
  }
end

local function missionRole(isServer, isClient, isMultiplayer, dynamicIsClient)
  local mission = {
    getIsServer = function() return isServer end,
    getIsClient = function() return isClient end,
  }
  if isMultiplayer ~= nil or dynamicIsClient ~= nil then
    mission.missionDynamicInfo = {
      isMultiplayer = isMultiplayer,
      isClient = dynamicIsClient,
    }
  end
  return mission
end

local function runLoad(mission)
  local enhancedVehicle = { mission = mission, version = "test" }
  FS25_EnhancedVehicle.loadMap(enhancedVehicle)
end

local function assertFeatures(value, label)
  for _, name in ipairs(featureNames) do
    local fieldName = "function" .. string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    assertEqual(FS25_EnhancedVehicle[fieldName], value, label .. " " .. name)
  end
end

local function configAPICallCount()
  local count = 0
  for _, calls in pairs(state.calls) do count = count + calls end
  return count
end

g_currentMission = nil
g_dedicatedServer = nil
g_dedicatedServerInfo = nil
lC = libConfig("FS25_EnhancedVehicle", 1, 0)

-- The early mission capability pair, not the late global, identifies a
-- headless server.  Stale profile files cannot disable authoritative defaults.
resetEngine()
installEV(evCurrentFile, false)
installEV(evOldFile, false)
runLoad(missionRole(true, false, true, false))
assertFalse(lC:getFileAccessAllowed(), "dedicated file policy")
assertFeatures(true, "dedicated defaults")
assertEqual(configAPICallCount(), 0, "dedicated zero config API calls")
assertEqual(state.opened, 0, "dedicated zero XML handles")
assertFalse(lC:loadConfigFile(evCurrentFile, true),
  "dedicated direct config load helper")
lC.migrationSourceFile = evOldFile
lC.confFile = evCurrentFile
lC:discardFailedMigrationTarget()
assertEqual(configAPICallCount(), 0, "dedicated helper APIs suppressed")

-- Sanitization and public immediate-write paths still mutate memory while the
-- central policy prevents every indirect filesystem operation.
lC:setConfigValue("snap", "snapToAngle", "invalid", true)
FS25_EnhancedVehicle:activateConfig()
FS25_EnhancedVehicle:functionEnable("snap", false)
assertEqual(configAPICallCount(), 0, "dedicated indirect writes suppressed")
assertEqual(state.opened, 0, "dedicated indirect zero XML handles")

-- The licensed -server lifecycle reports getIsClient()==true during load, but
-- exposes the earlier dedicated-process flag. This is still headless and must
-- be denied before any config operation.
resetEngine()
installEV(evCurrentFile, false)
installEV(evOldFile, false)
g_dedicatedServer = true
runLoad(missionRole(true, true, true, false))
assertFalse(lC:getFileAccessAllowed(), "server launch file policy")
assertFeatures(true, "server launch defaults")
assertEqual(configAPICallCount(), 0, "server launch zero config API calls")
assertEqual(state.opened, 0, "server launch zero XML handles")
local lateDedicatedMission = missionRole(true, true, true, false)
lateDedicatedMission.hud = { speedMeter = {}, gameInfoDisplay = {} }
g_gui = {}
FS25_EnhancedVehicle:onMissionLoaded(lateDedicatedMission)
g_gui = nil
g_dedicatedServer = nil

-- A hosted/listen server has both capabilities and retains normal config I/O.
resetEngine()
installEV(evCurrentFile, false)
-- A server-side dynamic role alone is intentionally not a dedicated signal.
runLoad(missionRole(true, true, true, false))
assertTrue(lC:getFileAccessAllowed(), "hosted file policy")
assertFeatures(false, "hosted stored values")
assertTrue(configAPICallCount() > 0, "hosted config API calls")
assertBalanced("hosted")

-- A following ordinary client on the same config object re-enables I/O and
-- completes a legacy migration, proving denial is mission-scoped.
resetEngine()
installEV(evOldFile, false)
g_dedicatedServer = true
g_dedicatedServerInfo = {}
runLoad(missionRole(false, true, true, true))
assertTrue(lC:getFileAccessAllowed(), "client file policy")
assertFeatures(false, "client migrated values")
assertTrue(state.files[evCurrentFile] ~= nil, "client migration current exists")
assertEqual(state.files[evOldFile], nil, "client migration old retired")
assertBalanced("client migration")
g_dedicatedServer = nil
g_dedicatedServerInfo = nil

-- Single-player is also server+client and therefore uses profile config.
resetEngine()
installEV(evCurrentFile, false)
runLoad(missionRole(true, true, false, true))
assertTrue(lC:getFileAccessAllowed(), "single-player file policy")
assertFeatures(false, "single-player stored values")
assertTrue(configAPICallCount() > 0, "single-player config API calls")
assertBalanced("single-player")

-- Re-entering dedicated mode recomputes denial and clean defaults again.
resetEngine()
installEV(evCurrentFile, false)
installEV(evOldFile, false)
runLoad(missionRole(true, false, true, false))
assertFalse(lC:getFileAccessAllowed(), "repeated dedicated file policy")
assertFeatures(true, "repeated dedicated defaults")
assertEqual(configAPICallCount(), 0, "repeated dedicated zero config API calls")

-- The late global remains only a defensive fallback when mission getters are
-- unavailable.
g_dedicatedServerInfo = {}
assertTrue(FS25_EnhancedVehicle.isDedicatedServerMission({}), "late dedicated fallback")
g_dedicatedServerInfo = nil
g_dedicatedServer = true
assertTrue(FS25_EnhancedVehicle.isDedicatedServerMission({}), "early dedicated fallback")
g_dedicatedServer = nil

print("Validated config migration, XML cleanup, and dedicated lifecycle isolation")
