-- One is my first script

engine.name = 'PolyPerc'

musicutil = require 'musicutil'

sequins = require 'sequins'

lfo = require 'lfo'

offset = 0
root = 60
scale = musicutil.generate_scale(root, "Dorian")
prob = 0 --probability of mutation
seqLen = 16 -- sequence length
seqPos = 1 -- sequence current position
seq = {}
fill = 0.75
screens = sequins

norns.enc.sens(1,4)
params:set('clock_tempo',96)

initSeq = function(len, random)
  local seq = {}
  for i = 1,len do
    if random then 
      seq[i] = {math.random(), math.random() < fill}
    else 
      seq[i] = {0.5, true} 
    end
  end
  return seq
end

getNext = function ()
  -- Maybe mutate 
  if math.random() < prob then
    seq[seqPos] = {math.random(), math.random() < fill}
  end
  return seq[seqPos]
end

function init()
 
  engine.release(1)
  engine.pw(0.3)
 
  seq = initSeq(seqLen, true)
  player = clock.run(play)
  
  filter_lfo = lfo.new(
    nil, -- shape will default to 'sine'
    400, -- min
    1200, -- max
    1, -- depth will default to 1
    'free', -- mode
    10, -- period (in 'free' mode, represents seconds)
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    function(scaled, raw) engine.cutoff(scaled) end -- action, always passes scaled and raw values
  )
  filter_lfo:start()
  
  filter_pw = lfo.new(
    nil, -- shape will default to 'sine'
    0.2, -- min
    0.8, -- max
    1, -- depth will default to 1
    'free', -- mode
    7, -- period (in 'free' mode, represents seconds)
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    function(scaled, raw) engine.pw(scaled) end -- action, always passes scaled and raw values
  )
  filter_pw:start()
  
  redraw()

end

range = 1*12 --octaves*semitones

note_from_value = function (val)
  noteNum = val*range - range/2 + root
  return musicutil.snap_note_to_array(noteNum, scale)
end

play = function()
  beat = 1/2  
  while true do
    clock.sync(beat)
    -- Maybe mutate parameters
    if math.random() < 0.6 then
      randomize()
    end
    -- play note and maybe mutate
    local noteGatePair = getNext()
    if noteGatePair[2] then
      engine.hz(musicutil.note_num_to_freq(note_from_value(noteGatePair[1])+offset))
    end
    redraw()
    if seqPos == seqLen then
      seqPos = 1
    else
      seqPos = seqPos + 1
    end
  end
end

randomize = function()
  engine.release(math.random() * (4-0.4) + 0.4)
end

function cleanup()
  clock.cancel(player)
end

function enc(n,d)
  
  if n==1 then
    local interval = 1
    if d > 0 then
      offset = offset+interval
    else
      offset = offset-interval
    end
  end
  
  if n==2 then
    params:set('clock_tempo',params:get('clock_tempo')+d)
  end
  
  if n==3 then
    local incr = 0.05
    if  d < 0 then
      incr = -1*incr
    end
    if prob+incr < 0.05 then 
      prob = 0
    elseif prob+incr > 1 then
      prob = 1
    else 
      prob = prob+incr
    end
  end
  
  redraw()
  
end

printBars = function()
  local gap = 4
  local barLen = 20
  local top = 40
  for x = 1,seqLen do
    -- get current note and gate
    local noteGatePair = seq[x]
    --print notes
    local scaledLen = math.floor((noteGatePair[1]*barLen)+0.5)
    if x == seqPos then
      screen.level(15)
    else
      screen.level(1)
    end
    screen.move((128-seqLen*gap)/2+x*gap, top)
    screen.line((128-seqLen*gap)/2+x*gap, top-scaledLen)
    screen.stroke()
    -- Print gates  
    if noteGatePair[2] then
      screen.move((128-seqLen*gap)/2+x*gap, top+2)
      screen.line((128-seqLen*gap)/2+x*gap, top+3)
      screen.stroke()
    end
  end
  screen.update()
end

-- screen: 128x64
function redraw()
  printBars()    
  screen.clear()
  
  --[[
  screen.move(46,30)
  screen.text('Offset: '..offset)
  screen.level(7)
  screen.move(46,38)
  screen.text('Tempo: '..params:get('clock_tempo'))
  screen.move(46,46)
  screen.text('Prob: '.. math.floor(prob*100+0.5) ..'%') -- round and truncate
  screen.update()
  ]]
end