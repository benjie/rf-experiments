fs = require 'fs'
express = require 'express'
SerialPort = require('serialport').SerialPort

delay = (ms, cb) -> setTimeout cb, ms

app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

app.configure ->
  app.use express.static __dirname + "/public"

server.listen 1337

TRANSMISSION_GAP = 10250
DURATION_TEN = 1250
DURATION_ONE = 250
DURATION_HIGH = 250

ERROR_MARGIN = 150

divisor = 60
analogReads = []

withinErrorMargin = (val, expected) ->
  margin = ERROR_MARGIN + expected/8
  return expected-margin < val < expected+margin

analyse = ->
  sensibleData = false
  isHigh = false
  bits = null
  outputted = []
  startIndex = null
  stopIndex = null

  endData = (index) ->
    stopIndex = index
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

  for l, index in analogReads
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
          #console.log "Low duration incorrect: #{l} !~= #{DURATION_ONE} or #{DURATION_TEN}"
          endData(index)
      isHigh = !isHigh
    if !sensibleData
      if withinErrorMargin(l, TRANSMISSION_GAP)
        #console.log "Starting logging data."
        startData(index)

  if startIndex ? 0 > stopIndex ? 0
    analogReads.splice(0,startIndex)
  else if stopIndex ? 0 > 0
    analogReads.splice(0, stopIndex)

  return

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

  ser.on 'open', ->
    console.error "Port open, capturing..."

    # Throw away first 1.5s of data
    delay 1500, ->
      toSend = new Buffer(3)
      toSend[0] = 'D'.charCodeAt(0)
      toSend[1] = divisor
      toSend[2] = 'c'.charCodeAt(0)
      ser.write toSend
      r = 0
      okay = 0

      ts = new Date().getTime()
      lastIndex = 0

      ser.on 'data', (data) ->
        for i in [0...data.length]
          val = data.readUInt8 i
          val *= divisor
          analogReads.push(val)
          if +new Date() - ts > 100
            ts = +new Date()
            io.sockets.emit 'new', analogReads.slice(lastIndex)
            lastIndex = analogReads.length
        return
