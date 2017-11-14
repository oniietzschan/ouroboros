require 'busted'

local Ouroboros = require 'ouroboros'

local function newGirl(name, moePoints)
  return setmetatable(
    {name = name, moePoints = moePoints},
    {__tostring = function(self) return self.name end}
  )
end

describe('Ouroboros:', function()
  local graph

  before_each(function()
    graph = Ouroboros.new()
  end)

  describe('When sorting an acyclic graph', function()
    it('Should sort the damn thing', function()
      graph
        :add('a', 'b')
        :add('b', 'c')
        :add('b', 'd')
        :add('d', 'c')

      local sorted, err = graph:sort()
      assert.same({'a', 'b', 'd', 'c'}, sorted)
      assert.same(nil, err)
    end)

    it('Should still work even if you add some weird shit', function()
      graph
        :add()
        :add(nil)
        :add('a')
        :add({'a', 'b'})

      local sorted, err = graph:sort()
      assert.same({'a', 'b'}, sorted)
      assert.same(nil, err)
    end)
  end)

  describe('When sorting a cyclic graph', function()
    describe('When no cycle resolution function is provided', function()
      it('Should fail with error message', function()
        graph
          :add('a', 'b')
          :add('b', 'c')
          :add('c', 'a')

        local sorted, err = graph:sort()
        assert.same(nil, sorted)
        assert.same('There is a circular dependency in the graph. Can not into a topological sort. Consider providing a cycle resolution function.', err)
      end)
    end)

    describe('When a resolution function is provided', function()
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

      it('Should be able to resolve cycle', function()
        local renge  = newGirl('Renge', 10000)
        local konata = newGirl('Konata', 5000)
        local umaru  = newGirl('Umaru',     0)
        graph
          :add(renge, konata)
          :add(konata, umaru)
          :add(umaru, renge)

        local sorted, err = graph:sort(resolveCycleFn)
        assert.same({renge, konata, umaru}, sorted)
        assert.same('Resolved 1 cycle(s) during topological sort.', err)
      end)

      it('Should be able to resolve cycle when cycle does not originate from first node in current visiting chain', function()
        local serval = newGirl('Serval', 7500)
        local renge  = newGirl('Renge', 10000)
        local konata = newGirl('Konata', 5000)
        local umaru  = newGirl('Umaru',     0)
        graph
          :add(serval, renge)
          :add(renge, konata)
          :add(konata, umaru)
          :add(umaru, renge)

        -- Assert that state BEFORE resolution is as expected.
        local nodes = graph.nodes
        assert.same({}, nodes[serval])
        assert.same({serval, umaru}, nodes[renge])
        assert.same({renge}, nodes[konata])
        assert.same({konata}, nodes[umaru])

        local cycle = {serval, renge, konata, umaru}
        graph:_resolveCycle(cycle, resolveCycleFn)

        -- Assert that state AFTER resolution is as expected.
        assert.same({}, nodes[serval])
        assert.same({serval}, nodes[renge]) -- Serval should have been removed from Renge's depencies
        assert.same({renge}, nodes[konata])
        assert.same({konata}, nodes[umaru])

        -- Since we manually resolved the cycle above, we don't expect to encounter any cycles now.
        local sorted, err = graph:sort()
        assert.same({serval, renge, konata, umaru}, sorted)
        assert.same(nil, err)
      end)
    end)

    describe('When an invalid resolution function is provided', function()
      it('Should throw error', function()
        graph
          :add('a', 'b')
          :add('b', 'a')

        local function badResolveCycleFn(cycle)
          return nil
        end

        local expectedError = 'cycleResolutionFn must return an item in the graph.'
        assert.has_error(function() graph:sort(badResolveCycleFn) end, expectedError)
      end)
    end)

    it('_visit() should return a complete cycle without extra nodes', function()
      graph
        :add('A', 'B')
        :add('B', 'C')
        :add('C', 'A')
        :add('A', 'Extra I')
        :add('Extra I', 'Extra II')

      local startingNode = 'Extra II'
      local marked = {}
      local sorted = {}

      local cycle = graph._visit(startingNode, graph.nodes, marked, sorted)
      assert.same({'A', 'B', 'C'}, cycle)
    end)

    it('_resolveCycle() should give error when cycleResolutionFn returns node which was not part of the cycle', function()
      graph
        :add('A', 'B')
        :add('B', 'C')
        :add('C', 'A')
        :add('A', 'Extra I')

      local cycle = {'A', 'B', 'C', 'Extra I'} -- Note: This is not actually a cycle...
      local function badResolveCycleFn(cycle)
        return 'Extra I'
      end

      local expectedError = 'Tried to remove dependency for Extra I, but it was not part of the cycle.'
      assert.has_error(function() graph:_resolveCycle(cycle, badResolveCycleFn) end, expectedError)
    end)
  end)
end)
