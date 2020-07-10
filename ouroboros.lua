--[[

ouroboros v0.0.0
================

Topological sorting in Lua. Simple cycle resolution functionality.

By shru. (see: https://github.com/oniietzschan/ouroboros)

LICENSE
-------

Whoever knows how to take, to defend, the "Software" — to him belongs property.

--]]

local Ouroboros = {}

function Ouroboros:add(...)
  local count = select('#', ...)
  local nodes = self.nodes
  for i = 1, count do
    local f = select(i, ...)
    if nodes[f] == nil then
      nodes[f] = {}
    end
  end
  for i = 2, count do
    local f = select(i, ...)
    local t = select(i - 1, ...)
    local o = nodes[f]
    table.insert(o, t)
  end
  return self
end

function Ouroboros:sort(cycleResolutionFn)
  assert(cycleResolutionFn == nil or type(cycleResolutionFn) == 'function')
  local err, cyclesResolved = nil, 0

  local sorted, cycle
  repeat
    sorted, cycle = self:_sort()
    if cycle then
      if cycleResolutionFn then
        self:_resolveCycle(cycle, cycleResolutionFn)
        cyclesResolved = cyclesResolved + 1
      else
        return nil, "There is a circular dependency in the graph. Can not into a topological sort. Consider providing a cycle resolution function."
      end
    end
  until cycle == nil

  if cyclesResolved >= 1 then
    err = 'Resolved ' .. cyclesResolved .. ' cycle(s) during topological sort.'
  end

  return sorted, err
end

do
  local marked = {}

  local function clearTable(t)
    for k in pairs(t) do
      t[k] = nil
    end
  end

  function Ouroboros:_sort()
    local sorted = {}
    local nodes = self.nodes
    clearTable(marked)
    for k in pairs(nodes) do
      if marked[k] == nil then
        local cycle = Ouroboros._visit(k, nodes, marked, sorted)
        if cycle then
          return nil, cycle
        end
      end
    end

    return sorted, nil
  end
end

local DEAD = 1
local PROCESSING = 0

function Ouroboros._visit(k, nodes, marked, sorted)
  if marked[k] == PROCESSING then
    return {k}, false
  elseif marked[k] == DEAD then
    return
  end
  marked[k] = PROCESSING
  local f = nodes[k]
  for i = 1, #f do
    local cycle, isCycleComplete = Ouroboros._visit(f[i], nodes, marked, sorted)
    if cycle then
      if isCycleComplete == false then
        for _, cycleNode in ipairs(cycle) do
          if cycleNode == k then
            isCycleComplete = true
            break
          end
        end
        if isCycleComplete == false then
          table.insert(cycle, k)
        end
      end
      return cycle, isCycleComplete
    end
  end
  marked[k] = DEAD
  table.insert(sorted, k)
end

function Ouroboros:_resolveCycle(cycle, cycleResolutionFn)
  local nodes = self.nodes
  local first = cycleResolutionFn(cycle)
  if first == nil or nodes[first] == nil then
    error('cycleResolutionFn must return an item in the graph.')
  end

  local inPriority = {}
  do
    local index
    for i, item in ipairs(cycle) do
      if item == first then
        index = (i == 1) and #cycle or i - 1
        break
      end
    end
    while true do
      local item = cycle[index]
      if item == first then
        break
      end
      table.insert(inPriority, item)
      index = index - 1
      if index == 0 then
        index = #cycle
      end
    end
  end

  for _, cycleNode in ipairs(inPriority) do
    for i, dependency in ipairs(nodes[cycleNode]) do
      if dependency == first then
        table.remove(nodes[cycleNode], i)
        return
      end
    end
  end

  error('Tried to remove dependency for ' .. tostring(first) .. ', but it was not part of the cycle.')
end

do
  local metatable = {
    __index = Ouroboros,
  }

  function Ouroboros.new()
    return setmetatable({ nodes = {} }, metatable)
  end
end

-- function Ouroboros:_debug(cycle, first, inPriority)
--   local str

--   str = 'Cycle:'
--   for i, item in ipairs(cycle) do
--     str = str .. ' ' .. tostring(item)
--   end
--   print(str)

--   print('First:', first)

--   str = 'inPriority:'
--   for i, item in ipairs(inPriority) do
--     str = str .. ' ' .. tostring(item)
--   end
--   print(str)

--   print('Dependencies:')
--   for i, item in ipairs(cycle) do
--     print('  - ' .. tostring(item))
--     for j, dep in ipairs(self.nodes[item]) do
--       print('    - ' .. tostring(dep))
--     end
--   end
-- end

return Ouroboros
