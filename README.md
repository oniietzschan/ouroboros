ouroboros
=========

[![Build Status](https://travis-ci.org/oniietzschan/ouroboros.svg?branch=master)](https://travis-ci.org/oniietzschan/ouroboros)
[![Codecov](https://codecov.io/gh/oniietzschan/ouroboros/branch/master/graph/badge.svg)](https://codecov.io/gh/oniietzschan/ouroboros)
[![Alex](https://img.shields.io/badge/alex-never_racist-brightgreen.svg)](http://alexjs.com/)

Topological sorting in Lua. Some cycle resolution functionality.

Example
-------

```lua
local Ouroboros = require "ouroboros"

local renge  = {name = 'Renge',  moePoints = 10000}
local konata = {name = 'Konata', moePoints =  5000}
local umaru  = {name = 'Umaru',  moePoints =     0}

local function resolveCycleFn(cycle)
  local worstGirl = nil
  local leastMoe = math.huge
  for i, girl in ipairs(cycle) do
    if girl.moePoints < leastMoe then
      leastMoe = girl.moePoints
      worstGirl = girl
    end
  end
  return worstGirl
end

local graph = Ouroboros.new()
graph:add(renge, konata)
graph:add(konata, umaru)
graph:add(umaru, renge)
local sorted, err = graph:sort(resolveCycleFn)

print((require "serpent").block(sorted))
-- {
--   {
--     moePoints = 10000,
--     name = "Renge"
--   },
--   {
--     moePoints = 5000,
--     name = "Konata"
--   },
--   {
--     moePoints = 0,
--     name = "Umaru"
--   }
-- }

print(err)
-- Resolved 1 cycle(s) during topological sort.
```