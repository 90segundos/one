--- Turing sequencer 
--

musicutil = require 'musicutil'

local Turing = {}

Turing.notes = {}
Turing.scale = 'Dorian'
Turing.prob = 0.1
Turing.fill = 0.5
Turing.octaves = 3
Turing.root = 60
Turing.seq = {}
Turing.seqPos = 1
Turing.steps = 16
Turing.offset = 0
Turing.beat = 1/2

function Turing.new(params)
  local t = {}
  -- Create a new instance using the incoming parameters
  t.root = params.root or Turing.root
  t.scale = params.scale or Turing.scale
  t.beat = params.beat or Turing.beat
  t.octaves = params.octaves or Turing.octaves
  setmetatable(t, self)
  self.__index = self
  return t
end

function Turing.setScale(scale)
  Turing.scale = scale or Turing.scale
end 

function Turing.setNotes(scaleName)
  Turing.notes = musicutil.generate_scale(Turing.root, scaleName, Turing.octaves)
end

function Turing.setRoot(root) Turing.root = root or 60 end 

function Turing.setBeat(beat) Turing.beat = beat or 1 end 

function Turing.setOctaves(octaves) Turing.octaves = octaves or 3 end 

function Turing.setProb(prob) Turing.prob = prob or 0.1 end 

function Turing.setSteps(length) 
  Turing.steps = length or Turing.steps
end 

function Turing.createStep(level, gate)
  return {
    level = math.max(0, math.min(1, note or math.random())),  -- Ensure note is between 0 and 1
    gate = gate == nil and (math.random() < Turing.fill) or gate  -- Use fill probability if gate is not provided
  } 
end

function Turing.getStep()
  if math.random() < Turing.prob then
    Turing.seq[Turing.seqPos] = Turing.createStep()
  end
  return Turing.seq[Turing.seqPos]

end

function Turing.getNextStep()
  Turing.incrementSeqPos() 
  return Turing.getStep()
end

function Turing.getPrevStep()
  Turing.decreaseSeqPos() 
  return Turing.getStep()
end

function Turing.incrementSeqPos()
  if Turing.seqPos >= Turing.steps then
    Turing.seqPos = 1
  else
    Turing.seqPos = Turing.seqPos + 1
  end
end

function Turing.decreaseSeqPos()
  if Turing.seqPos <= 1 then
    Turing.seqPos = Turing.steps
  else
    Turing.seqPos = Turing.seqPos - 1
  end
end

function Turing.next()
  local step = getNextStep()
  return {
    note = Turing.quantizeLevel(step.level),
    gate = step.gate,
  }
end

function Turing.quantizeLevel(level)
  local note = level*12*Turing.octaves+Turing.root
  return musicutil.snap_note_to_array(note, Turing.notes)
end

function Turing.redraw() return end 

return Turing