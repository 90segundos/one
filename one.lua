-- One is my first script

engine.name = 'PolyPerc'
musicutil = require 'musicutil'
ui = require 'ui'
lfo = require 'lfo'

function init()
 
  norns.enc.sens(1,4)
  params:set('clock_tempo',96)
  engine.release(1)
  engine.pw(0.3)

  offset = 0
  notes = {}
  prob = 0.10 --probability of mutation
  -- seqLen = 16 -- sequence length
  seqPos = 1 -- sequence current position
  seq = {}
  alt = false

  params:add_separator("ONE")
  
  params:add{
    type = "control",
    id = "fill",
    name = "note fill",
    controlspec = controlspec.def{
      min = 0,
      max = 1,
      warp = "lin",
      step = 0.1,
      default = 0.5,
    }
  }
  
  params:add{
    type = "number",
    id = "seqLen",
    name = "seq. length",
    min = 1,
    max = 32,
    default = 16,
  }
  
  params:add{
    type = "number",
    id = "octaves",
    name = "octaves",
    min = 1,
    max = 4,
    default = 2,
  }
  
  params:add{
    type = "number",
    id = "root_note",
    name = "root note",
    min = 0,
    max = 127,
    default = 48,
    formatter = function(param) return musicutil.note_num_to_name(param:get(), true) end,
  }
  params:set_action("root_note", function() setScale(params:get("scale")) end)
  
  root = params:get("root_note")
  
  params:add_option(
    "scale",
    "scale",
    get_scale_names(),
    2
  )
  params:set_action("scale",function(name) setScale(name) end)
  
  params:bang() -- initialize
  
  --[[
  params:add_text("test", "Test", "Hello!")
  
  params:bang()

  ]]
  
  delay_rate = params:get('clock_tempo')/60 / 1.3
  
  -- configure the delay
  audio.level_cut(1.0)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level(1,1.0)
  softcut.level_slew_time(1,0.25)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.pan(1, 0.0)
  softcut.play(1, 1)
  softcut.rate(1, 1)
  softcut.rate_slew_time(1,3.0)
  softcut.loop_start(1, 0)
  softcut.loop_end(1, delay_rate)
  softcut.loop(1, 1)
  --softcut.fade_time(1, 0)
  softcut.rec(1, 1)
  softcut.rec_level(1, 1)
  softcut.pre_level(1, 0.4) --[[ 0_0 ]]--
  softcut.position(1, 0)
  softcut.enable(1, 1)
  softcut.pre_filter_dry(1, 0);
  softcut.pre_filter_lp(1, 0.0);
  softcut.pre_filter_bp(1, .5);
  softcut.pre_filter_hp(1, 1);
  softcut.pre_filter_fc(1, 1200);
  softcut.pre_filter_rq(1, 2);
 
  seq = initSeq(params:get("seqLen"), true)
  
  --probDial = newProbDial()
  --probDial:redraw()
  
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
  
  -- Dials
  dials = {}
  -- UI.Dial.new (x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title)
  --dials[1] = ui.Dial.new( 2, 2, 40, prob, 0, 1)
  dials[1] = ui.Slider.new(54,50,20,1,prob,0,1,{},"right")
  redraw()
end

initSeq = function(len, random)
  local seq = {}
  for i = 1,len do
    if random then 
      seq[i] = {math.random(), math.random() < params:get("fill")}
    else 
      seq[i] = {0.5, true} 
    end
  end
  return seq
end

setScale = function(name)
  notes = musicutil.generate_scale(params:get('root_note'), name, params:get("octaves"))
end


getNext = function()
  -- Maybe mutate 
  if math.random() < prob then
    seq[seqPos] = {math.random(), math.random() < params:get("fill")}
  end
  return seq[seqPos]
end

-- Function to generate a list of scale names
get_scale_names = function()
  local scale_names = {}
  for i, notes in ipairs(musicutil.SCALES) do
    table.insert(scale_names, notes.name)
  end
  return scale_names
end

note_from_value = function (val)
  noteNum = val*12*params:get("octaves")+params:get("root_note")
  return musicutil.snap_note_to_array(noteNum, notes)
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
    if seqPos >= params:get("seqLen") then
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
  if player then
    clock.cancel(player)
  end
end

function enc(n,d)
  
  if n==1 then
    set_note_interval_delta(d)
  end
  
  if n==2 then
    set_clock_tempo_delta(d)
  end
  
  if n==3 then
    if alt then 
      set_delay_rate_delta(d)
    else
      set_prob_delta(d)
    end
  end
  
  redraw()
  
end

function key(n,z)
  if n == 1 then alt = 1 == z end
  if alt then print('alt: true') else print('alt: false') end
end

set_prob_delta = function(d)
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
  dials[1]:set_value(prob)
end


set_delay_rate_delta = function(d)
  if delay_rate+d*0.05 < 0.05 then
    delay_rate = 0.05
  elseif delay_rate+d*0.05 > 10 then
    delay_rate = 10
  else
    delay_rate = delay_rate+d*0.05
  end
  softcut.loop_end(1, delay_rate)
end

set_clock_tempo_delta = function (d)
  params:set('clock_tempo',params:get('clock_tempo')+d)
end

set_note_interval_delta = function (d)
  local interval = 1
  if d > 0 then
    offset = offset+interval
  else
    offset = offset-interval
  end
end

printBars = function()
  local gap = 4
  local barLen = 20
  local top = 40
  local seqLen = params:get("seqLen")
  for x = 1,seqLen do
    -- get current note and gate
    local noteGatePair = seq[x]
    --print notes
    local scaledLen = math.ceil((noteGatePair[1]*barLen)-0.5)
    if x == seqPos then
      screen.level(15)
    else
      if noteGatePair[2] then
        screen.level(8)
      else 
        screen.level(1)
      end
    end
    screen.move((128-seqLen*gap)/2+x*gap, top)
    screen.line((128-seqLen*gap)/2+x*gap, top-scaledLen)
    screen.stroke()
    -- Print gates 
    --[[
    if noteGatePair[2] then
      screen.move((128-seqLen*gap)/2+x*gap, top+2)
      screen.line((128-seqLen*gap)/2+x*gap, top+3)
      screen.stroke()
    end
    ]]
  end
  screen.update()
end

newProbDial = function() 
  return ui.Dial.new(
    0, -- x
    0, -- y
    22, -- diameter
    0, -- value
    0, -- min_value
    1, -- max_value
    0.01, -- rounding
    0, -- start_value
    {}, -- markers
    '', -- units
    '' -- title
  )
end

-- screen: 128x64
function redraw()
  screen.clear()
  printBars()
  
  dials[1]:redraw()
  
  --screen.level(7)
  --screen.move(46,30)
  --screen.text('Offset: '..offset)
  --screen.move(46,38)
  --screen.text('Tempo: '..params:get('clock_tempo'))
  --screen.move(46,64-12)
  --screen.text('Prob: '.. math.floor(prob*100+0.5) ..'%') -- round and truncate
  screen.update()
end