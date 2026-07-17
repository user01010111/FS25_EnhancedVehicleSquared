-- Enhanced Vehicle Squared legacy-compatible loader
--
-- Maintained by user01010111 with Enhanced Vehicle Squared contributors.
-- See LICENSE and ATTRIBUTION.md.
--





debug = 0 -- 0 = off, 1 = basic, 2 = verbose, 3 = trace

local directory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("FS25_EnhancedVehicle.lua", directory))
source(Utils.getFilename("FS25_EnhancedVehicle_Event.lua", directory))
source(Utils.getFilename("ui/FS25_EnhancedVehicle_UI.lua", directory))
source(Utils.getFilename("ui/FS25_EnhancedVehicle_HUD.lua", directory))
source(Utils.getFilename("ui/FS25_EnhancedVehicle_LineRenderer.lua", directory))

-- Retain the legacy source and global identifiers as compatibility ABI.
source(Utils.getFilename("libUtils.lua", g_currentModDirectory))
lU = libUtils()
lU:setDebug(0)

-- Versioned configuration keys remain FS25_EnhancedVehicle_v0/v1.
source(Utils.getFilename("libConfig.lua", g_currentModDirectory))
lC = libConfig("FS25_EnhancedVehicle", 1, 0)
lC:setDebug(0)

local EnhancedVehicle

local function isEnabled()
  return EnhancedVehicle ~= nil
end



function EV_init()
  if debug > 1 then print("EV_init()") end
  

  Mission00.load = Utils.prependedFunction(Mission00.load, EV_load)

  Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, EV_loadedMission)

  -- Release mod-owned HUD, GUI, scene, and audio resources before mission teardown.
  FSBaseMission.delete = Utils.prependedFunction(FSBaseMission.delete, EV_unload)


  TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, EV_validateTypes)
end



function EV_load(mission)
  if debug > 1 then print("EV_load()") end
  

  assert(g_EnhancedVehicle == nil)
  local inputManager = g_gui ~= nil and g_gui.inputManager or nil
  EnhancedVehicle = FS25_EnhancedVehicle:new(mission, directory, modName, g_i18n, g_gui, inputManager, g_messageCenter)
  getfenv(0)["g_EnhancedVehicle"] = EnhancedVehicle

  mission.EnhancedVehicle = EnhancedVehicle

  addModEventListener(EnhancedVehicle);
end



function EV_unload()
  if debug > 1 then print("EV_unload()") end

  if not isEnabled() then
    return
  end

  removeModEventListener(EnhancedVehicle)
  
  EnhancedVehicle:delete()
  EnhancedVehicle = nil
  getfenv(0)["g_EnhancedVehicle"] = nil
end



function EV_loadedMission(mission)
  if debug > 1 then print("EV_load()") end

  if not isEnabled() then
    return
  end

  if mission.cancelLoading then
    return
  end

  EnhancedVehicle:onMissionLoaded(mission)
end



function EV_validateTypes(types)
  if debug > 1 then print("EV_validateTypes()") end
    

  if (types.typeName == 'vehicle') then
    FS25_EnhancedVehicle.installSpecializations(g_vehicleTypeManager, g_specializationManager, directory, modName)
  end
end



EV_init()
