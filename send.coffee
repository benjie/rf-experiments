fs = require 'fs'
SerialPort = require('serialport').SerialPort
process.on 'uncaughtException', (err) ->
  console.log('Caught exception: ' + err)
  console.log err.stack

delay = (ms, cb) -> setTimeout cb, ms
divisor = 40

TRANSMISSION_GAP = 10250
DURATION_TEN = 1250
DURATION_ONE = 250
DURATION_HIGH = 250

ERROR_MARGIN = 150

lookup = [
  "11110110",
  "11101110",
  "11101101",
  "11101011",
  "11011110",
  "11011101",
  "11011011",
  "10111110",
  "10111101",
  "10111011",
  "10110111",
  "01111110",
  "01111101",
  "01111011",
  "01110111",
  "01101111"
]

encodeLightwaveRF = (remote, subUnit=0, command=1, level=0) ->
  if level > 0
    level += 0x80
  nibbles = [
    (level >> 4) & 0xf
    level & 0xf
    subUnit & 0xf
    command & 0xf
  ]
  offset = 6
  while offset
    offset--
    nibbles.push ((remote >> offset*4) & 0xf)
  for nibble, i in nibbles
    nibbles[i] = lookup[nibble]
  string = "11"+nibbles.join("1")+"1"
  string = string.replace /10/g, "_"
  delays = [TRANSMISSION_GAP]
  for i in [0...string.length]
    delays.push DURATION_HIGH
    c = string.charAt i
    if c is '1'
      delays.push DURATION_ONE
    else if c is '_'
      delays.push DURATION_TEN
  console.log JSON.stringify delays
  return delays

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

analyse = (array) ->
  sensibleData = false
  isHigh = false
  bits = null
  outputted = []
  startIndex = null

  endData = (index) ->
    sensibleData = false
    #bits.shift 1
    binStr = bits.join ""
    if binStr.length < 8
      return
    if outputted.indexOf(binStr) is -1
      outputted.push binStr
      #console.log "#{startIndex} -> #{index} : "
      console.log binStr.substr(1).replace /1(....)(....)/g, " 1  $1 $2 "
      console.error binStr.substr(1).replace /1(....)(....)/g, " 1  $1 $2 "

  startData = (index) ->
    startIndex = index
    sensibleData = true
    isHigh = true
    bits = []

  for l, index in array
    if sensibleData
      if isHigh
        #if !withinErrorMargin(l, DURATION_HIGH)
        if l > DURATION_HIGH + ERROR_MARGIN
          isHigh = false
          #console.log "High duration incorrect: #{l} !~= #{DURATION_HIGH}"
          #endData()
      if !isHigh
        if withinErrorMargin(l, DURATION_ONE)
          bits.push "1"
        else if withinErrorMargin(l, DURATION_TEN)
          bits.push "10"
        else
          #console.log "Low duration incorrect: #{l} !~= #{DURATION_ONE} or #{DURATION_ZERO}"
          endData(index)
      isHigh = !isHigh
    if !sensibleData
      if withinErrorMargin(l, TRANSMISSION_GAP)
        #console.log "Starting logging data."
        startData(index)

if process.argv[2]?
  filename = process.argv[2]
  filename ?= 'dump.json'
  array = JSON.parse fs.readFileSync filename, 'utf8'
  analyse array
else
  # Capture the data

  console.error "Opening port..."
  ser = new SerialPort '/dev/ttyACM0',
    baudrate: 57600 #76800

  sendLightwaveRF = (args...) ->
    delays = encodeLightwaveRF.apply @, args
    for dur, i in delays
      delays[i] = Math.round(dur/divisor)
    toSend = new Buffer(delays.length+3)
    toSend[0] = 's'.charCodeAt(0)
    toSend[1] = delays.length
    toSend[2] = 8 # 8 repeats
    for dur, i in delays
      toSend[3+i] = dur
    console.log toSend
    ser.write(toSend)
    console.log "Sent #{toSend.length}"
    return

  ser.on 'close', ->
    console.error "CLOSED!"

  ser.on 'data', (data) ->
    console.log data#.toString('utf8')

  ser.on 'open', ->
    delay 1500, ->
      toSend = new Buffer(2)
      toSend[0] = 'D'.charCodeAt(0)
      toSend[1] = divisor
      ser.write toSend
      sendLightwaveRF 0xF30537, 13, 1, 5
