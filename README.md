ouroboros
=========

[![Build Status](https://travis-ci.org/oniietzschan/ouroboros.svg?branch=master)](https://travis-ci.org/oniietzschan/ouroboros)
[![Codecov](https://codecov.io/gh/oniietzschan/ouroboros/branch/master/graph/badge.svg)](https://codecov.io/gh/oniietzschan/ouroboros)
![Lua Versions](https://img.shields.io/badge/Lua-JIT%2C%205.1%2C%205.2%2C%205.3-blue.svg)

Topological sorting in Lua. Simple cycle resolution functionality.

Basic Example
-------------

```lua
local Ouroboros = require "ouroboros"

local graph = Ouroboros.new()
  :add('b', 'e')
  :add('b', 'c', 'd')
  :add('d', 'e')
  :add('a', 'b')

local sorted = graph:sort()
print((require "serpent").line(sorted))
-- {'a', 'b', 'c', 'd', 'e'}
```

Cycle Resolution Example
------------------------

```lua
local Ouroboros = require "ouroboros"

local konata = {name = 'Konata', moePoints =  5000}
local renge  = {name = 'Renge',  moePoints = 10000}
local umaru  = {name = 'Umaru',  moePoints =     0}

-- This graph has a cycle: konata -> renge -> umaru -> konata -> ...
local graph = Ouroboros.new()
  :add(konata, renge)
  :add(renge, umaru)
  :add(umaru, konata)

-- graph:sort() can take a function which it will consult in order to decide
-- which dependency should be severed in order to make the graph acyclic again.
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

local sorted, err = graph:sort(resolveCycleFn)

print((require "serpent").block(sorted))
-- {
--   {
--     name = "Konata",
--     moePoints = 5000
--   },
--   {
--     name = "Renge",
--     moePoints = 10000
--   },
--   {
--     name = "Umaru",
--     moePoints = 0
--   }
-- }

print(err)
-- Resolved 1 cycle(s) during topological sort.
```
