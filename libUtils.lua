--
-- Library: libUtils (for Farming Simulator 22++)
--
-- Maintained by Enhanced Vehicle Squared contributors.
-- Derived from Enhanced Vehicle; see ATTRIBUTION.md and LICENSE.
-- @Date: 17.07.2026
-- @Version: 1.0.0.1

-- #############################################################################

local myName = "libUtils"

libUtils = {}
libUtils.__index = libUtils

setmetatable(libUtils, {
  __call = function (cls, ...)
  local self = setmetatable({}, cls)

  self.debug = 0
  self:new(...)

  return self
  end,
})

-- #############################################################################

function libUtils:new()
  if self.debug > 0 then print("-> libUtils: new()") end
end

-- #############################################################################

function libUtils:setDebug(dbg)
  self.debug = dbg or 0
end

-- #############################################################################

function libUtils:args_to_txt(...)
  local args = { ... }
  local txt = ""
  for i, v in ipairs(args) do
    if i > 1 then
      txt = txt .. ", "
    end
    txt = txt .. i .. ": " .. tostring(v)
  end

  return(txt)
end
