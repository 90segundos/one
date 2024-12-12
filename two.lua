-- TWO

engine.name = 'PolyPerc'
musicutil = require 'musicutil'
Turing = require 'lib/turing'

function init()
  turing = Turing.new()
end

function key(n, z)
  local step = turing.next()
  print('Note: '..step.note .. ' Gate: '..step.gate)
end

function cleanup() end

function redraw()
  -- screen: 128x64
  screen.clear()
  screen.update()
end