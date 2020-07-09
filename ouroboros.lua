local Ouroboros = {
  _VERSION     = 'ouroboros v0.0.0',
  _URL         = 'https://github.com/oniietzschan/ouroboros',
  _DESCRIPTION = 'Topological sorting in Lua. Simple cycle resolution functionality.',
  _LICENSE     = [[
    Massachusecchu... あれっ！ Massachu... chu... chu... License!

    Copyright (c) 1789 Retia Adolf

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED 【AS IZ】, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE. PLEASE HAVE A FUN AND BE GENTLE WITH THIS SOFTWARE.
  ]]
}

function Ouroboros.new()
  return setmetatable({ nodes = {} }, {__index = Ouroboros})
end

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

function Ouroboros:_sort()
  local nodes = self.nodes
  local sorted = {}
  local marked = {}
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

  for i, cycleNode in ipairs(inPriority) do
    for j, dependency in ipairs(nodes[cycleNode]) do
      if dependency == first then
        table.remove(nodes[cycleNode], j)
        return
      end
    end
  end

  error('Tried to remove dependency for ' .. tostring(first) .. ', but it was not part of the cycle.')
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
