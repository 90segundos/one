-- One is my first script

engine.name = 'PolyPerc'
musicutil = require 'musicutil'
lfo = require 'lfo'
offset = 0
root = 60
scale = musicutil.generate_scale(root, "Minor Pentatonic")
prob = 0 --probability of mutation
seqLen = 16 -- sequence length
seqPos = 1 -- sequence current position
seq = {}

norns.enc.sens(1,4)
params:set('clock_tempo', 80)
engine.release(1)
engine.pw(0.3)

initSeq = function(len, random)
  local seq = {}
  for i = 1,len do
    if random then 
      seq[i] = scale[math.random(1,#scale)] 
    else 
      seq[i] = root 
    end
  end
  return seq
end

mutateSeq = function()
  for i = 1,#seq do
    if math.random() < prob then
      local pos = math.random(1,#scale)
      seq[i] = scale[pos]
    end
  end
end

getNote = function ()
  -- Maybe mutate 
  if math.random() < prob then
    seq[seqPos] = scale[math.random(1,#scale)]
  end
  return seq[seqPos]
end


function init()
 
  seq = initSeq(seqLen, false)
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
    engine.hz(musicutil.note_num_to_freq(getNote()+offset))
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
    if prob+incr < 0 then 
      prob = 0
    elseif prob+incr > 1 then
      prob = 1
    else 
      prob = prob+incr
    end
  end
  
  redraw()
  
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(20,20)
  
  for bar = 1,#seq do
    screen.line_width(1)
    screen.line_rel(0,5)
    screen.move_rel(1,0)
  end
  
  screen.move(46,30)
  screen.text('Offset: '..offset)
  screen.level(7)
  screen.move(46,38)
  screen.text('Tempo: '..params:get('clock_tempo'))
  screen.move(46,46)
  screen.text('Prob: '.. math.ceil(prob*100) ..'%')
  screen.update()
end


